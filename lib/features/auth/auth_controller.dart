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
import '../dashboard/manager_dashboard.dart';
import '../dashboard/member_dashboard.dart';
import '../dashboard/organizer_dashboard.dart';
import 'login_view.dart';

/// Controller autentikasi dengan pendekatan offline-first.
///
/// Fitur utama:
/// - Login offline-first (Hive -> fallback cloud)
/// - Seeding admin default saat first run
/// - CRUD user khusus admin
/// - State reactive dengan ValueNotifier
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

  Future<void> initializeAuth() async {
    await seedDefaultAdminIfNeeded();
  }

  // seedDefaultAdminIfNeeded()
Future<void> seedDefaultAdminIfNeeded() async {
  try {
    final hasAdmin = _hasAnyLocalAdmin();
    if (hasAdmin) {
      debugPrint('[Auth][seed] skipped: admin already exists');
      return;
    }

    final memberId = _uuid.v4();
    final nowIso = DateTime.now().toIso8601String();
    final seededAdmin = <String, dynamic>{
      'memberId': memberId,
      'nama': AppConstants.defaultAdminName,
      'nim': AppConstants.defaultAdminNim,
      'divisi': AppConstants.defaultAdminDivision,
      'role': AppConstants.roleAdmin,
      'password': _hashPassword(AppConstants.defaultAdminPassword),
      'qrData': QrService.generateQrData(memberId),
      'isSynced': false,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    };

    final seededMember = <String, dynamic>{
      'memberId': memberId,
      'nama': AppConstants.defaultAdminName,
      'nim': AppConstants.defaultAdminNim,
      'divisi': AppConstants.defaultAdminDivision,
      'role': AppConstants.roleMember,
      'password': _hashPassword(AppConstants.defaultAdminPassword),
      'qrData': QrService.generateQrData(memberId),
      'isSynced': false,
      'createdAt': nowIso,
      'updatedAt': nowIso,
    };

    await HiveService.members.put(memberId, _memberFromMap(seededAdmin));
    await HiveService.members.put(memberId, _memberFromMap(seededMember));

    debugPrint(
      '[Auth][seed] default admin created nim=${AppConstants.defaultAdminNim}',
    );

    unawaited(_syncUpsertUserInBackground(memberId: memberId, userDoc: seededAdmin));
  } catch (e, st) {
    debugPrint('[Auth][seed] error: $e');
    debugPrint(st.toString());
  }
}

  Future<bool> createUserByAdmin({
    required String nama,
    required String nim,
    required String divisi,
    required String role,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserAdmin()) {
        errorMessage.value = 'Hanya admin yang dapat membuat akun.';
        return false;
      }

      final normalizedRole = _normalizeRole(role);
      debugPrint('[Auth][createUser] start nim=$nim role=$normalizedRole');

      final existing = _findLocalUserByNim(nim);
      if (existing != null) {
        errorMessage.value = 'NIM sudah terdaftar.';
        debugPrint('[Auth][createUser] failed: duplicate nim in local');
        return false;
      }

      final memberId = _uuid.v4();
      final nowIso = DateTime.now().toIso8601String();
      final localDoc = <String, dynamic>{
        'memberId': memberId,
        'nama': nama.trim(),
        'nim': nim.trim(),
        'divisi': divisi.trim(),
        'role': normalizedRole,
        'password': _hashPassword(password),
        'qrData': QrService.generateQrData(memberId),
        'isSynced': false,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      await HiveService.members.put(memberId, _memberFromMap(localDoc));      
      debugPrint('[Auth][createUser] local saved memberId=$memberId');
      unawaited(_syncUpsertUserInBackground(memberId: memberId, userDoc: localDoc));
      return true;
    } catch (e, st) {
      debugPrint('[Auth][createUser] error: $e');
      debugPrint(st.toString());
      errorMessage.value = 'Gagal membuat akun user.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<MemberModel>> getAllUsers() async {
    final users = <MemberModel>[];
    for (final raw in HiveService.members.values) {
      final doc = _toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        continue;
      }
      users.add(_memberFromMap(doc));
    }
    users.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return users;
  }

  Future<bool> updateUserByAdmin({
    required String memberId,
    String? nama,
    String? divisi,
    String? role,
    String? password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserAdmin()) {
        errorMessage.value = 'Hanya admin yang dapat mengubah akun.';
        return false;
      }

      final raw = HiveService.members.get(memberId);
      final currentDoc = _toMap(raw);
      if (currentDoc == null || !_isUserDocument(currentDoc)) {
        errorMessage.value = 'User tidak ditemukan.';
        return false;
      }

      final updatedDoc = Map<String, dynamic>.from(currentDoc);
      if (nama != null && nama.trim().isNotEmpty) {
        updatedDoc['nama'] = nama.trim();
      }
      if (divisi != null && divisi.trim().isNotEmpty) {
        updatedDoc['divisi'] = divisi.trim();
      }
      if (role != null && role.trim().isNotEmpty) {
        updatedDoc['role'] = _normalizeRole(role);
      }
      if (password != null && password.isNotEmpty) {
        updatedDoc['password'] = _hashPassword(password);
      }

      updatedDoc['isSynced'] = false;
      updatedDoc['updatedAt'] = DateTime.now().toIso8601String();

      await HiveService.members.put(memberId, _memberFromMap(updatedDoc));
      debugPrint('[Auth][updateUser] local updated memberId=$memberId');

      if (currentUser.value?.memberId == memberId) {
        currentUser.value = _memberFromMap(updatedDoc);
      }

      unawaited(_syncUpsertUserInBackground(memberId: memberId, userDoc: updatedDoc));
      return true;
    } catch (e, st) {
      debugPrint('[Auth][updateUser] error: $e');
      debugPrint(st.toString());
      errorMessage.value = 'Gagal memperbarui user.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUserByAdmin(String memberId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserAdmin()) {
        errorMessage.value = 'Hanya admin yang dapat menghapus akun.';
        return false;
      }

      final raw = HiveService.members.get(memberId);
      final doc = _toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        errorMessage.value = 'User tidak ditemukan.';
        return false;
      }

      await HiveService.members.delete(memberId);
      debugPrint('[Auth][deleteUser] local deleted memberId=$memberId');

      if (currentUser.value?.memberId == memberId) {
        clearSession();
      }

      unawaited(_deleteUserFromCloudInBackground(memberId));
      return true;
    } catch (e, st) {
      debugPrint('[Auth][deleteUser] error: $e');
      debugPrint(st.toString());
      errorMessage.value = 'Gagal menghapus user.';
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

          await HiveService.members.put(memberId, _memberFromMap(userDoc));
          debugPrint('[Auth][login] cloud hit -> cached locally memberId=$memberId');
        }
      }

      if (userDoc == null) {
        errorMessage.value = 'Akun tidak ditemukan.';
        debugPrint('[Auth][login] failed: user not found');
        return false;
      }

      userDoc['role'] = _normalizeRole((userDoc['role'] ?? '').toString());
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

  Future<void> _syncUpsertUserInBackground({
    required String memberId,
    required Map<String, dynamic> userDoc,
  }) async {
    try {
      if (!await _isOnline()) {
        debugPrint('[Auth][syncUpsert] skipped: offline memberId=$memberId');
        return;
      }

      final synced = await _upsertUserToCloud(userDoc);
      if (!synced) {
        debugPrint('[Auth][syncUpsert] postponed: cloud sync failed memberId=$memberId');
        return;
      }

      final localDoc = Map<String, dynamic>.from(userDoc)
        ..['isSynced'] = true
        ..['updatedAt'] = DateTime.now().toIso8601String();

      await HiveService.members.put(memberId, _memberFromMap(localDoc));
      debugPrint('[Auth][syncUpsert] success: local sync flag updated memberId=$memberId');
    } catch (e) {
      debugPrint('[Auth][syncUpsert] error memberId=$memberId -> $e');
    }
  }

  Future<void> _deleteUserFromCloudInBackground(String memberId) async {
    try {
      if (!await _isOnline()) {
        debugPrint('[Auth][syncDelete] skipped: offline memberId=$memberId');
        return;
      }

      final deleted = await _deleteUserFromCloud(memberId);
      if (deleted) {
        debugPrint('[Auth][syncDelete] success memberId=$memberId');
      }
    } catch (e) {
      debugPrint('[Auth][syncDelete] error memberId=$memberId -> $e');
    }
  }

  Future<bool> _upsertUserToCloud(Map<String, dynamic> userDoc) async {
    final payload = _toCloudPayload(userDoc);
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();
    final memberId = (payload['memberId'] ?? '').toString();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.put(
          '$baseUrl/users/$memberId',
          data: payload,
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          debugPrint('[Auth][syncUpsert] cloud API success status=$statusCode');
          return true;
        }

        debugPrint('[Auth][syncUpsert] cloud API non-success status=$statusCode');
      } catch (e) {
        debugPrint('[Auth][syncUpsert] cloud API failed, fallback to MongoService: $e');
      }
    }

    try {
      final existing = await MongoService.instance.findOne(
        collectionName: AppConstants.usersCollection,
        filter: {'memberId': memberId},
      );

      if (existing == null) {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.usersCollection,
          document: payload,
        );
      } else {
        await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'memberId': memberId},
          updateFields: payload,
        );
      }

      debugPrint('[Auth][syncUpsert] mongo_dart upsert success');
      return true;
    } catch (e) {
      if (MongoService.isDuplicateKeyError(e)) {
        debugPrint('[Auth][syncUpsert] duplicate user on cloud, treated as synced');
        return true;
      }
      debugPrint('[Auth][syncUpsert] mongo_dart upsert failed: $e');
      return false;
    }
  }

  Future<bool> _deleteUserFromCloud(String memberId) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.delete(
          '$baseUrl/users/$memberId',
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          return true;
        }
      } catch (e) {
        debugPrint('[Auth][syncDelete] cloud API failed, fallback to MongoService: $e');
      }
    }

    try {
      await MongoService.instance.deleteOne(
        collectionName: AppConstants.usersCollection,
        filter: {'memberId': memberId},
      );
      return true;
    } catch (e) {
      debugPrint('[Auth][syncDelete] mongo_dart delete failed: $e');
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
    final normalizedRole = _normalizeRole(role);
    final Widget destination;

    switch (normalizedRole) {
      case AppConstants.roleAdmin:
        destination = const AdminDashboard();
        break;
      case AppConstants.roleManager:
        destination = const ManagerDashboard();
        break;
      case AppConstants.roleOrganizer:
        destination = const OrganizerDashboard();
        break;
      default:
        destination = const MemberDashboard();
    }

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
      role: _normalizeRole((doc['role'] ?? AppConstants.roleMember).toString()),
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

  bool _isCurrentUserAdmin() {
    return _normalizeRole(currentUser.value?.role ?? '') == AppConstants.roleAdmin;
  }

  bool _hasAnyLocalAdmin() {
    for (final raw in HiveService.members.values) {
      final doc = _toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        continue;
      }

      if (_normalizeRole((doc['role'] ?? '').toString()) == AppConstants.roleAdmin) {
        return true;
      }
    }
    return false;
  }

  bool _isUserDocument(Map<String, dynamic> doc) {
    return (doc['memberId']?.toString().isNotEmpty ?? false) &&
        (doc['nim']?.toString().isNotEmpty ?? false);
  }

  String _normalizeRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (AppConstants.allowedRoles.contains(normalized)) {
      return normalized;
    }
    return AppConstants.roleMember;
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    currentUser.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}