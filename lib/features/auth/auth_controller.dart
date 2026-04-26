import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/network_status_controller.dart';
import '../../core/utils/qr_service.dart';
import '../../models/member_model.dart';
import '../dashboard/dashboard_view.dart';
import 'login_view.dart';
import '../../core/services/fcm_service.dart';

/// Controller autentikasi dengan pendekatan offline-first.
///
/// Fitur utama:
/// - Login offline-first (Hive -> fallback cloud)
/// - Seeding Executive default saat first run
/// - CRUD user khusus Executive
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
      ) {
    _onlineListener = () {
      if (NetworkStatusController.instance.isOnline.value) {
        unawaited(_syncPendingUserChanges());
      }
    };
    NetworkStatusController.instance.isOnline.addListener(_onlineListener);
  }

  final Dio _dio;
  late final VoidCallback _onlineListener;

  final ValueNotifier<MemberModel?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<void> initializeAuth() async {
    await seedDefaultAccount();
    unawaited(_syncPendingUserChanges());
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
        final needsRepair =
            existing != null &&
            (_normalizeRole((existing['role'] ?? '').toString()) != role ||
                !_verifyPassword(
                  password,
                  (existing['password'] ?? '').toString(),
                ) ||
                (existing['nama'] ?? '').toString().trim().isEmpty ||
                (existing['divisi'] ?? '').toString().trim().isEmpty);

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
          'qrCodeValue': QrService.generateQrData(normalizedNim),
          'memberId': normalizedNim,
          'isSynced': false,
          'createdAt': (existing?['createdAt'] ?? nowIso).toString(),
          'updatedAt': nowIso,
        };

        await HiveService.members.put(normalizedNim, _memberFromMap(merged));
        _enqueuePendingUpsert(normalizedNim);
        unawaited(
          _syncUpsertUserInBackground(nim: normalizedNim, userDoc: merged),
        );

        if (needsCreate) {
          debugPrint(
            '[Auth][seed] created default account nim=$normalizedNim role=$role',
          );
        } else {
          debugPrint(
            '[Auth][seed] repaired default account nim=$normalizedNim role=$role',
          );
        }
      }

      await ensureDefaultAccount(
        nim: AppConstants.defaultExecutiveNim,
        nama: AppConstants.defaultExecutiveName,
        divisi: AppConstants.defaultExecutiveDivision,
        role: AppConstants.roleExecutive,
        password: AppConstants.defaultExecutivePassword,
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
        '[Auth][seed] default accounts ensured/repaired (Executive/member/organizer/manager)',
      );
    } catch (e, st) {
      debugPrint('[Auth][seed] error: $e');
      debugPrint(st.toString());
    }
  }

  Future<bool> createUserByExecutive({
    required String nama,
    required String nim,
    required String divisi,
    required String role,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat membuat akun.';
        return false;
      }

      final normalizedRole = _normalizeRole(role);
      final normalizedNim = nim.trim();
      final normalizedNama = nama.trim();
      final normalizedDivisi = divisi.trim();
      debugPrint('[Auth][createUser] start nim=$nim role=$normalizedRole');

      if (normalizedNim.isEmpty ||
          normalizedNama.isEmpty ||
          normalizedDivisi.isEmpty ||
          password.isEmpty) {
        errorMessage.value = 'NIM, Nama, Role, DBU, dan Password wajib diisi.';
        return false;
      }

      final existing = _findLocalUserByNim(normalizedNim);
      if (existing != null) {
        errorMessage.value = 'NIM sudah terdaftar.';
        debugPrint('[Auth][createUser] failed: duplicate nim in local');
        return false;
      }

      final nowIso = DateTime.now().toIso8601String();
      final localDoc = <String, dynamic>{
        'nama': normalizedNama,
        'nim': normalizedNim,
        'divisi': normalizedDivisi,
        'role': normalizedRole,
        'password': _hashPassword(password),
        'qrCodeValue': QrService.generateQrData(normalizedNim),
        'memberId': normalizedNim,
        'isSynced': false,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      await HiveService.members.put(normalizedNim, _memberFromMap(localDoc));
      debugPrint('[Auth][createUser] local saved nim=$normalizedNim');
      _enqueuePendingUpsert(normalizedNim);
      unawaited(
        _syncUpsertUserInBackground(nim: normalizedNim, userDoc: localDoc),
      );
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

  Future<bool> updateUserByExecutive({
    required String nim,
    String? nama,
    String? divisi,
    String? role,
    String? password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat mengubah akun.';
        return false;
      }

      final storageKey = _resolveLocalStorageKey(nim);
      final raw = storageKey != null
          ? HiveService.members.get(storageKey)
          : null;
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

      await HiveService.members.put(
        updatedStorageKey,
        _memberFromMap(updatedDoc),
      );
      debugPrint('[Auth][updateUser] local updated nim=$updatedStorageKey');
      _enqueuePendingUpsert(updatedStorageKey);

      if (currentUser.value?.nim == nim.trim()) {
        currentUser.value = _memberFromMap(updatedDoc);
      }

      unawaited(
        _syncUpsertUserInBackground(
          nim: updatedStorageKey,
          userDoc: updatedDoc,
        ),
      );
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

  Future<bool> deleteUserByExecutive(String nim) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat menghapus akun.';
        return false;
      }

      final storageKey = _resolveLocalStorageKey(nim);
      final raw = storageKey != null
          ? HiveService.members.get(storageKey)
          : null;
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
      _dequeuePendingUpsert(nimToDelete);
      _enqueuePendingDelete(nimToDelete);
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
      // Pastikan akun default selalu tersedia dan data login lokal ter-repair.
      await seedDefaultAccount();

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
          debugPrint(
            '[Auth][login] cloud hit -> cached locally nim=$storageKey',
          );
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

      // Update FCM token di background saat login (Week 8)
      final loggedNim = (userDoc['nim'] ?? normalizedNim).toString().trim();
      unawaited(_updateFcmTokenInBackground(loggedNim));

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
      _enqueuePendingUpsert(nim);

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
      _dequeuePendingUpsert(storageKey);
      _dequeuePendingUpsert(nim);
      debugPrint(
        '[Auth][syncUpsert] success: local sync flag updated nim=$storageKey',
      );
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
        _dequeuePendingDelete(nim);
        debugPrint('[Auth][syncDelete] success nim=$nim');
      }
    } catch (e) {
      debugPrint('[Auth][syncDelete] error nim=$nim -> $e');
    }
  }

  Future<void> _syncPendingUserChanges() async {
    if (!await _isOnline()) {
      return;
    }

    await _syncPendingUserUpserts();
    await _syncPendingUserDeletes();
  }

  Future<void> _syncPendingUserUpserts() async {
    final pendingNims = HiveService.pendingUserUpserts.values
        .map((nim) => nim.trim())
        .where((nim) => nim.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (final nim in pendingNims) {
      final storageKey = _resolveLocalStorageKey(nim);
      if (storageKey == null) {
        _dequeuePendingUpsert(nim);
        continue;
      }

      final member = HiveService.members.get(storageKey);
      final doc = _toMap(member);
      if (doc == null || !_isUserDocument(doc)) {
        _dequeuePendingUpsert(nim);
        continue;
      }

      final synced = await _upsertUserToCloud(doc);
      if (synced) {
        _dequeuePendingUpsert(nim);
      }
    }
  }

  Future<void> _syncPendingUserDeletes() async {
    final pendingNims = HiveService.pendingUserDeletes.values
        .map((nim) => nim.trim())
        .where((nim) => nim.isNotEmpty)
        .toSet()
        .toList(growable: false);

    for (final nim in pendingNims) {
      final deleted = await _deleteUserFromCloud(nim);
      if (deleted) {
        _dequeuePendingDelete(nim);
      }
    }
  }

  void _enqueuePendingUpsert(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserUpserts.put(normalizedNim, normalizedNim);
  }

  void _dequeuePendingUpsert(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserUpserts.delete(normalizedNim);
  }

  void _enqueuePendingDelete(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserDeletes.put(normalizedNim, normalizedNim);
  }

  void _dequeuePendingDelete(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserDeletes.delete(normalizedNim);
  }

  Future<void> _updateFcmTokenInBackground(String nim) async {
    try {
      final token = await FcmService.instance.getFcmToken();
      if (token == null) {
        debugPrint('[Auth][fcm] token null — skip (FcmService masih stub)');
        return;
      }

      final storageKey = _resolveLocalStorageKey(nim);
      if (storageKey == null) return;

      final member = HiveService.members.get(storageKey);
      if (member == null) return;

      // Update token di Hive (in-place)
      member.fcmToken = token;
      await member.save();
      debugPrint('[Auth][fcm] token updated in Hive for nim=$nim');

      // Sync ke MongoDB di background
      if (await _isOnline()) {
        await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'nim': nim},
          updateFields: {'fcmToken': token},
        );
        debugPrint('[Auth][fcm] token synced to MongoDB for nim=$nim');
      }
    } catch (e) {
      debugPrint('[Auth][fcm] update failed: $e');
      // Tidak perlu throw — ini fire-and-forget
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

        debugPrint(
          '[Auth][syncUpsert] cloud API non-success status=$statusCode',
        );
      } catch (e) {
        debugPrint(
          '[Auth][syncUpsert] cloud API failed, fallback to MongoService: $e',
        );
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
        debugPrint(
          '[Auth][syncUpsert] duplicate user on cloud, treated as synced',
        );
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
        debugPrint(
          '[Auth][syncDelete] cloud API failed, fallback to MongoService: $e',
        );
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
        debugPrint(
          '[Auth][login] cloud API read failed, fallback to MongoService: $e',
        );
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const DashboardView()),
      (route) => false,
    );
  }

  Map<String, dynamic> _toCloudPayload(Map<String, dynamic> doc) {
    return <String, dynamic>{
      'memberId': doc['memberId'] ?? doc['nim'],
      'nama': doc['nama'],
      'nim': doc['nim'],
      'divisi': doc['divisi'],
      'role': doc['role'],
      'qrCodeValue': doc['qrCodeValue'] ?? doc['qrData'],
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
    final nim = (doc['nim'] ?? '').toString().trim();
    return MemberModel(
      memberId: (doc['memberId'] ?? nim).toString().trim(),
      nim: nim,
      nama: (doc['nama'] ?? '').toString(),
      divisi: (doc['divisi'] ?? '').toString(),
      role: _normalizeRole((doc['role'] ?? AppConstants.roleMember).toString()),
      password: (doc['password'] ?? '').toString(),
      qrCodeValue: (doc['qrCodeValue'] ?? doc['qrData'] ?? '').toString(),
      fcmToken: doc['fcmToken']?.toString(),
    );
  }

  Map<String, dynamic>? _toMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is MemberModel) {
      return <String, dynamic>{
        'memberId': raw.memberId,
        'nama': raw.nama,
        'nim': raw.nim,
        'divisi': raw.divisi,
        'role': raw.role,
        'password': raw.password,
        'qrCodeValue': raw.qrCodeValue,
        'fcmToken': raw.fcmToken,
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
    final offsetBasis = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask64 = BigInt.parse('ffffffffffffffff', radix: 16);
    const String pepper = 'PRASASTI_AUTH_V1';

    BigInt hash = offsetBasis;
    final bytes = utf8.encode('$pepper:$password');
    for (final b in bytes) {
      hash = (hash ^ BigInt.from(b));
      hash = (hash * prime) & mask64;
    }

    return 'h1:${hash.toRadixString(16).padLeft(16, '0')}';
  }

  bool _verifyPassword(String inputPassword, String storedPassword) {
    final hashedInput = _hashPassword(inputPassword);
    if (storedPassword == hashedInput) return true;

    // Backward compatibility untuk data lama yang masih plain text.
    return storedPassword == inputPassword;
  }

  bool _isCurrentUserExecutive() {
    return _normalizeRole(currentUser.value?.role ?? '') ==
        AppConstants.roleExecutive;
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

  /// Verifikasi credentials tanpa navigasi — HANYA untuk unit test
  Future<bool> verifyCredentials({
    required String nim,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final normalizedNim = nim.trim();
      final userDoc = _findLocalUserByNim(normalizedNim);
      if (userDoc == null) {
        errorMessage.value = 'Akun tidak ditemukan.';
        return false;
      }
      userDoc['role'] = _normalizeRole((userDoc['role'] ?? '').toString());
      final savedPassword = (userDoc['password'] ?? '').toString();
      if (!_verifyPassword(password, savedPassword)) {
        errorMessage.value = 'Password salah.';
        return false;
      }
      currentUser.value = _memberFromMap(userDoc);
      return true;
    } catch (e) {
      errorMessage.value = 'Verifikasi gagal.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    NetworkStatusController.instance.isOnline.removeListener(_onlineListener);
    currentUser.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
