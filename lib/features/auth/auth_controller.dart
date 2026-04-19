import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/qr_service.dart';
import '../../models/member_model.dart';
import '../dashboard/admin_dashboard.dart';
import '../dashboard/member_dashboard.dart';
import 'login_view.dart';

/// Controller autentikasi dengan pendekatan offline-first.
///
/// Flow utama:
/// - Register: simpan lokal dulu (Hive) -> sync cloud background (non-blocking)
/// - Login: cari lokal dulu -> fallback cloud -> cache lokal
/// - State UI: reactive via ValueNotifier (tanpa setState)
class AuthController {
  static final AuthController instance = AuthController._internal();

  AuthController._internal()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: AppConstants.networkTimeout,
            receiveTimeout: AppConstants.networkTimeout,
            sendTimeout: AppConstants.networkTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  final Dio _dio;
  final Uuid _uuid = const Uuid();

  final ValueNotifier<MemberModel?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<bool> register({
    required String nama,
    required String nim,
    required String divisi,
    required String role,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      debugPrint('[Auth][register] start nim=$nim role=$role');

      final existing = _findLocalUserByNim(nim);
      if (existing != null) {
        errorMessage.value = 'NIM sudah terdaftar.';
        debugPrint('[Auth][register] failed: duplicate nim in local');
        return false;
      }

      final memberId = _uuid.v4();
      final hashedPassword = _hashPassword(password);
      final qrData = QrService.generateQrData(memberId);
      final nowIso = DateTime.now().toIso8601String();

      final localDoc = <String, dynamic>{
        'memberId': memberId,
        'nama': nama.trim(),
        'nim': nim.trim(),
        'divisi': divisi.trim(),
        'role': role.trim(),
        'password': hashedPassword,
        'qrData': qrData,
        'isSynced': false,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      await HiveService.members.put(memberId, localDoc);
      debugPrint('[Auth][register] local saved memberId=$memberId');

      currentUser.value = _memberFromMap(localDoc);

      // Sync cloud berjalan di background agar UX tetap cepat (offline-first).
      unawaited(_syncUserInBackground(memberId: memberId, userDoc: localDoc));
      return true;
    } catch (e, st) {
      debugPrint('[Auth][register] error: $e');
      debugPrint(st.toString());
      errorMessage.value = 'Registrasi gagal. Silakan coba lagi.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login({
    required BuildContext context,
    required String nim,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final normalizedNim = nim.trim();
      debugPrint('[Auth][login] start nim=$normalizedNim');

      Map<String, dynamic>? userDoc = _findLocalUserByNim(normalizedNim);

      if (userDoc == null) {
        debugPrint('[Auth][login] local miss -> checking cloud');
        userDoc = await _fetchUserFromCloud(normalizedNim);

        if (userDoc != null) {
          userDoc['isSynced'] = true;
          final memberId = (userDoc['memberId'] ?? _uuid.v4()).toString();
          userDoc['memberId'] = memberId;

          await HiveService.members.put(memberId, userDoc);
          debugPrint('[Auth][login] cloud hit -> cached locally memberId=$memberId');
        }
      }

      if (userDoc == null) {
        errorMessage.value = 'Akun tidak ditemukan.';
        debugPrint('[Auth][login] failed: user not found');
        return false;
      }

      final savedPassword = (userDoc['password'] ?? '').toString();
      if (!_verifyPassword(password, savedPassword)) {
        errorMessage.value = 'Password salah.';
        debugPrint('[Auth][login] failed: invalid password');
        return false;
      }

      currentUser.value = _memberFromMap(userDoc);
      debugPrint('[Auth][login] success role=${currentUser.value?.role}');

      _navigateByRole(context, currentUser.value?.role ?? '');
      return true;
    } catch (e, st) {
      debugPrint('[Auth][login] error: $e');
      debugPrint(st.toString());
      errorMessage.value = 'Login gagal. Silakan coba lagi.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('[Auth][logout] clearing session');
    clearSession();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  void clearSession() {
    currentUser.value = null;
    errorMessage.value = null;
  }

  Future<void> _syncUserInBackground({
    required String memberId,
    required Map<String, dynamic> userDoc,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((r) => r != ConnectivityResult.none);
      if (!isOnline) {
        debugPrint('[Auth][sync] skipped: offline memberId=$memberId');
        return;
      }

      final synced = await _pushUserToCloud(userDoc);
      if (!synced) {
        debugPrint('[Auth][sync] postponed: cloud sync failed memberId=$memberId');
        return;
      }

      final localDoc = Map<String, dynamic>.from(userDoc)
        ..['isSynced'] = true
        ..['updatedAt'] = DateTime.now().toIso8601String();

      await HiveService.members.put(memberId, localDoc);
      debugPrint('[Auth][sync] success: local sync flag updated memberId=$memberId');
    } catch (e) {
      debugPrint('[Auth][sync] error memberId=$memberId -> $e');
    }
  }

  Future<bool> _pushUserToCloud(Map<String, dynamic> userDoc) async {
    final payload = _toCloudPayload(userDoc);
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.post(
          '$baseUrl/users',
          data: payload,
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          debugPrint('[Auth][sync] cloud API success status=$statusCode');
          return true;
        }

        debugPrint('[Auth][sync] cloud API non-success status=$statusCode');
      } catch (e) {
        debugPrint('[Auth][sync] cloud API failed, fallback to MongoService: $e');
      }
    }

    try {
      await MongoService.instance.insertOne(
        collectionName: AppConstants.usersCollection,
        document: payload,
      );
      debugPrint('[Auth][sync] mongo_dart insert success');
      return true;
    } catch (e) {
      if (MongoService.isDuplicateKeyError(e)) {
        debugPrint('[Auth][sync] duplicate user on cloud, treated as synced');
        return true;
      }
      debugPrint('[Auth][sync] mongo_dart insert failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserFromCloud(String nim) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.get(
          '$baseUrl/users',
          queryParameters: {'nim': nim},
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          final doc = _extractUserMapFromApiResponse(response.data);
          if (doc != null) {
            debugPrint('[Auth][login] cloud API hit');
            return doc;
          }
        }
      } catch (e) {
        debugPrint('[Auth][login] cloud API read failed, fallback to MongoService: $e');
      }
    }

    try {
      final doc = await MongoService.instance.findOne(
        collectionName: AppConstants.usersCollection,
        filter: {'nim': nim},
      );

      if (doc != null) {
        debugPrint('[Auth][login] mongo_dart cloud hit');
      }
      return doc;
    } catch (e) {
      debugPrint('[Auth][login] mongo_dart read failed: $e');
      return null;
    }
  }

  Map<String, dynamic>? _findLocalUserByNim(String nim) {
    final normalizedNim = nim.trim();
    final values = HiveService.members.values;

    for (final raw in values) {
      final doc = _toMap(raw);
      if (doc == null) continue;

      final savedNim = (doc['nim'] ?? '').toString().trim();
      if (savedNim == normalizedNim) {
        return doc;
      }
    }
    return null;
  }

  void _navigateByRole(BuildContext context, String role) {
    final normalizedRole = role.trim();
    final Widget destination = normalizedRole == AppConstants.roleAdmin
        ? const AdminDashboard()
        : const MemberDashboard();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => destination),
      (route) => false,
    );
  }

  Map<String, dynamic> _toCloudPayload(Map<String, dynamic> doc) {
    return <String, dynamic>{
      'memberId': doc['memberId'],
      'nama': doc['nama'],
      'nim': doc['nim'],
      'divisi': doc['divisi'],
      'role': doc['role'],
      'password': doc['password'],
      'qrData': doc['qrData'],
      'createdAt': doc['createdAt'],
      'updatedAt': doc['updatedAt'],
    };
  }

  MemberModel _memberFromMap(Map<String, dynamic> doc) {
    return MemberModel(
      memberId: (doc['memberId'] ?? _uuid.v4()).toString(),
      nama: (doc['nama'] ?? '').toString(),
      nim: (doc['nim'] ?? '').toString(),
      divisi: (doc['divisi'] ?? '').toString(),
      role: (doc['role'] ?? AppConstants.roleMember).toString(),
      password: (doc['password'] ?? '').toString(),
      qrData: (doc['qrData'] ?? '').toString(),
    );
  }

  Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    if (raw is MemberModel) {
      return <String, dynamic>{
        'memberId': raw.memberId,
        'nama': raw.nama,
        'nim': raw.nim,
        'divisi': raw.divisi,
        'role': raw.role,
        'password': raw.password,
        'qrData': raw.qrData,
      };
    }

    return null;
  }

  Map<String, dynamic>? _extractUserMapFromApiResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
      }
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(first);
      }
      if (first is Map) {
        return first.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    return null;
  }

  String _hashPassword(String password) {
    // FNV-1a 64-bit style hashing + app pepper untuk menghindari plain text.
    const int offsetBasis = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    const String pepper = 'PRASASTI_AUTH_V1';

    int hash = offsetBasis;
    final bytes = utf8.encode('$pepper:$password');
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }

    return 'h1:${hash.toRadixString(16).padLeft(16, '0')}';
  }

  bool _verifyPassword(String inputPassword, String storedPassword) {
    final hashedInput = _hashPassword(inputPassword);
    if (storedPassword == hashedInput) return true;

    // Backward compatibility untuk data lama yang masih plain text.
    return storedPassword == inputPassword;
  }

  void dispose() {
    currentUser.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}