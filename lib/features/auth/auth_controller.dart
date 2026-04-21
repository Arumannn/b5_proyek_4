import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  final ValueNotifier<MemberModel?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<void> initializeAuth() async {
    await seedDefaultAccount();
  }

  // seedDefaultAccount()
Future<void> seedDefaultAccount() async {
  try {
    final nowIso = DateTime.now().toIso8601String();

    Future<void> ensureDefaultAccount({
      required String nim,
      required String nama,
      required String divisi,
      required String role,
      required String password,
    }) async {
      final normalizedNim = nim.trim();
      final existing = _findLocalUserByNim(normalizedNim);
      final hashedDefaultPassword = _hashPassword(password);

      final needsCreate = existing == null;
      final needsRepair = existing != null && (
        _normalizeRole((existing['role'] ?? '').toString()) != role ||
        !_verifyPassword(password, (existing['password'] ?? '').toString()) ||
        (existing['nama'] ?? '').toString().trim().isEmpty ||
        (existing['divisi'] ?? '').toString().trim().isEmpty
      );

      if (!needsCreate && !needsRepair) {
        return;
      }

      final merged = <String, dynamic>{
        ...?existing,
        'nim': normalizedNim,
        'nama': nama,
        'divisi': divisi,
        'role': role,
        'password': hashedDefaultPassword,
        'qrData': QrService.generateQrData(normalizedNim),
        'isSynced': false,
        'createdAt': (existing?['createdAt'] ?? nowIso).toString(),
        'updatedAt': nowIso,
      };

      await HiveService.members.put(normalizedNim, _memberFromMap(merged));
      unawaited(_syncUpsertUserInBackground(nim: normalizedNim, userDoc: merged));

      if (needsCreate) {
        debugPrint('[Auth][seed] created default account nim=$normalizedNim role=$role');
      } else {
        debugPrint('[Auth][seed] repaired default account nim=$normalizedNim role=$role');
      }
    }

    await ensureDefaultAccount(
      nim: AppConstants.defaultAdminNim,
      nama: AppConstants.defaultAdminName,
      divisi: AppConstants.defaultAdminDivision,
      role: AppConstants.roleAdmin,
      password: AppConstants.defaultAdminPassword,
    );

    await ensureDefaultAccount(
      nim: AppConstants.defaultMemberNim,
      nama: AppConstants.defaultMemberName,
      divisi: AppConstants.defaultMemberDivision,
      role: AppConstants.roleMember,
      password: AppConstants.defaultMemberPassword,
    );

    await ensureDefaultAccount(
      nim: AppConstants.defaultOrganizerNim,
      nama: AppConstants.defaultOrganizerName,
      divisi: AppConstants.defaultOrganizerDivision,
      role: AppConstants.roleOrganizer,
      password: AppConstants.defaultOrganizerPassword,
    );

    await ensureDefaultAccount(
      nim: AppConstants.defaultManagerNim,
      nama: AppConstants.defaultManagerName,
      divisi: AppConstants.defaultManagerDivision,
      role: AppConstants.roleManager,
      password: AppConstants.defaultManagerPassword,
    );

    debugPrint(
      '[Auth][seed] default accounts ensured/repaired (admin/member/organizer/manager)',
    );
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
      final normalizedNim = nim.trim();
      debugPrint('[Auth][createUser] start nim=$nim role=$normalizedRole');

      final existing = _findLocalUserByNim(normalizedNim);
      if (existing != null) {
        errorMessage.value = 'NIM sudah terdaftar.';
        debugPrint('[Auth][createUser] failed: duplicate nim in local');
        return false;
      }

      final nowIso = DateTime.now().toIso8601String();
      final localDoc = <String, dynamic>{
        'nama': nama.trim(),
        'nim': normalizedNim,
        'divisi': divisi.trim(),
        'role': normalizedRole,
        'password': _hashPassword(password),
        'qrData': QrService.generateQrData(normalizedNim),
        'isSynced': false,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      await HiveService.members.put(normalizedNim, _memberFromMap(localDoc));
      debugPrint('[Auth][createUser] local saved nim=$normalizedNim');
      unawaited(_syncUpsertUserInBackground(nim: normalizedNim, userDoc: localDoc));
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
    required String nim,
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

      final storageKey = _resolveLocalStorageKey(nim);
      final raw = storageKey != null ? HiveService.members.get(storageKey) : null;
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

        final nimStorageKey = (updatedDoc['nim'] ?? '').toString().trim();
        final updatedStorageKey = nimStorageKey.isNotEmpty
          ? nimStorageKey
            : (storageKey ?? nim.trim());

        await HiveService.members.put(updatedStorageKey, _memberFromMap(updatedDoc));
        debugPrint('[Auth][updateUser] local updated nim=$updatedStorageKey');

        if (currentUser.value?.nim == nim.trim()) {
        currentUser.value = _memberFromMap(updatedDoc);
      }

        unawaited(_syncUpsertUserInBackground(nim: updatedStorageKey, userDoc: updatedDoc));
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

  Future<bool> deleteUserByAdmin(String nim) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserAdmin()) {
        errorMessage.value = 'Hanya admin yang dapat menghapus akun.';
        return false;
      }

      final storageKey = _resolveLocalStorageKey(nim);
      final raw = storageKey != null ? HiveService.members.get(storageKey) : null;
      final doc = _toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        errorMessage.value = 'User tidak ditemukan.';
        return false;
      }

      await HiveService.members.delete(storageKey);
      debugPrint('[Auth][deleteUser] local deleted nim=$nim');

      if (currentUser.value?.nim == nim.trim()) {
        clearSession();
      }

      final nimToDelete = (doc['nim'] ?? nim).toString().trim();
      unawaited(_deleteUserFromCloudInBackground(nimToDelete));
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
          final cloudNim = (userDoc['nim'] ?? normalizedNim).toString().trim();
          userDoc['nim'] = cloudNim;

          final storageKey = cloudNim.isNotEmpty ? cloudNim : normalizedNim;
          await HiveService.members.put(storageKey, _memberFromMap(userDoc));
          debugPrint('[Auth][login] cloud hit -> cached locally nim=$storageKey');
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

      try {
        final fcmToken = await FcmService.instance.getFcmToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          final updatedUser = userDoc;
          updatedUser['fcmToken'] = fcmToken;
          
          final nimStorageKey = (updatedUser['nim'] ?? normalizedNim).toString().trim();
          final storageKey = nimStorageKey.isNotEmpty ? nimStorageKey : normalizedNim;
          await HiveService.members.put(storageKey, _memberFromMap(updatedUser));
          
          // Background sync FCM token to cloud
          unawaited(_syncUpsertUserInBackground(nim: storageKey, userDoc: updatedUser));
          
          debugPrint('[Auth][login] FCM token updated: ${fcmToken.substring(0, 20)}...');
        }
      } catch (e) {
        debugPrint('[Auth][login] FCM token update failed (non-critical): $e');
      }

      currentUser.value = _memberFromMap(userDoc);

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
    required String nim,
    required Map<String, dynamic> userDoc,
  }) async {
    try {
      if (!await _isOnline()) {
        debugPrint('[Auth][syncUpsert] skipped: offline nim=$nim');
        return;
      }

      final synced = await _upsertUserToCloud(userDoc);
      if (!synced) {
        debugPrint('[Auth][syncUpsert] postponed: cloud sync failed nim=$nim');
        return;
      }

      final localDoc = Map<String, dynamic>.from(userDoc)
        ..['isSynced'] = true
        ..['updatedAt'] = DateTime.now().toIso8601String();

      final nimStorageKey = (localDoc['nim'] ?? '').toString().trim();
      final storageKey = nimStorageKey.isNotEmpty ? nimStorageKey : nim;
      await HiveService.members.put(storageKey, _memberFromMap(localDoc));
      debugPrint('[Auth][syncUpsert] success: local sync flag updated nim=$storageKey');
    } catch (e) {
      debugPrint('[Auth][syncUpsert] error nim=$nim -> $e');
    }
  }

  Future<void> _deleteUserFromCloudInBackground(String nim) async {
    try {
      if (!await _isOnline()) {
        debugPrint('[Auth][syncDelete] skipped: offline nim=$nim');
        return;
      }

      final deleted = await _deleteUserFromCloud(nim);
      if (deleted) {
        debugPrint('[Auth][syncDelete] success nim=$nim');
      }
    } catch (e) {
      debugPrint('[Auth][syncDelete] error nim=$nim -> $e');
    }
  }

  Future<bool> _upsertUserToCloud(Map<String, dynamic> userDoc) async {
    final payload = _toCloudPayload(userDoc);
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();
    final nim = (payload['nim'] ?? '').toString().trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.put(
          '$baseUrl/users/$nim',
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
        filter: {'nim': nim},
      );

      if (existing == null) {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.usersCollection,
          document: payload,
        );
      } else {
        await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'nim': nim},
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

  Future<bool> _deleteUserFromCloud(String nim) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.delete(
          '$baseUrl/users/$nim',
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
        filter: {'nim': nim},
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

  String? _resolveLocalStorageKey(String nim) {
    final candidate = nim.trim();
    if (candidate.isEmpty) {
      return null;
    }

    if (HiveService.members.containsKey(candidate)) {
      return candidate;
    }

    for (final entry in HiveService.members.toMap().entries) {
      final doc = _toMap(entry.value);
      if (doc == null) continue;

      final savedNim = (doc['nim'] ?? '').toString().trim();
      if (savedNim == candidate) {
        return entry.key.toString();
      }
    }

    return null;
  }

  MemberModel _memberFromMap(Map<String, dynamic> doc) {
    return MemberModel(
      nim: (doc['nim'] ?? '').toString(),
      nama: (doc['nama'] ?? '').toString(),
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

  bool _isUserDocument(Map<String, dynamic> doc) {
    return doc['nim']?.toString().trim().isNotEmpty ?? false;
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