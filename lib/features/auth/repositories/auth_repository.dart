import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/auth_local_data_source.dart';
import '../data/auth_remote_data_source.dart';
import '../../../models/member_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/qr_service.dart';

class AuthRepository {
  final AuthLocalDataSource _local;
  final AuthRemoteDataSource _remote;

  AuthRepository(this._local, this._remote);

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
        final existing = _local.findLocalUserByNim(normalizedNim);
        final hashedDefaultPassword = hashPassword(password);

        final needsCreate = existing == null;
        final needsRepair =
            existing != null &&
            (_local.normalizeRole((existing['role'] ?? '').toString()) !=
                    _local.normalizeRole(role) ||
                !verifyPassword(
                  password,
                  (existing['password'] ?? '').toString(),
                ) ||
                (existing['nama'] ?? '').toString().trim().isEmpty ||
                (existing['divisi'] ?? '').toString().trim().isEmpty);

        if (!needsCreate && !needsRepair) return;

        final merged = <String, dynamic>{
          ...?existing,
          'nim': normalizedNim,
          'nama': nama,
          'divisi': divisi,
          'role': _local.normalizeRole(role),
          'password': hashedDefaultPassword,
          'qrCodeValue': QrService.generateQrData(normalizedNim),
          'isSynced': false,
          'createdAt': (existing?['createdAt'] ?? nowIso).toString(),
          'updatedAt': nowIso,
        };

        await _local.saveUser(normalizedNim, merged);
        _local.enqueuePendingUpsert(normalizedNim);
        await syncUpsertUserInBackground(nim: normalizedNim, userDoc: merged);
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
    } catch (e, st) {
      debugPrint('[AuthRepo][seed] error: $e');
      debugPrint(st.toString());
    }
  }

  Future<MemberModel?> login(String nim, String password) async {
    final normalizedNim = nim.trim();
    Map<String, dynamic>? userDoc = _local.findLocalUserByNim(normalizedNim);

    if (userDoc == null) {
      userDoc = await _remote.fetchUserFromCloud(normalizedNim);
      if (userDoc != null) {
        userDoc['isSynced'] = true;
        final cloudNim = (userDoc['nim'] ?? normalizedNim).toString().trim();
        userDoc['nim'] = cloudNim;

        final storageKey = cloudNim.isNotEmpty ? cloudNim : normalizedNim;
        await _local.saveUser(storageKey, userDoc);
      }
    }

    if (userDoc == null) {
      throw Exception('Akun tidak ditemukan.');
    }

    userDoc['role'] = _local.normalizeRole((userDoc['role'] ?? '').toString());
    final savedPassword = (userDoc['password'] ?? userDoc['passwordHash'] ?? '').toString();
    if (!verifyPassword(password, savedPassword)) {
      throw Exception('Password salah.');
    }

    final cloudDoc = await _remote.fetchUserFromCloud(normalizedNim);
    if (cloudDoc != null) {
      userDoc = {
        ...userDoc,
        if ((cloudDoc['organizationId'] ?? cloudDoc['organization_id']) != null)
          'organizationId':
              cloudDoc['organizationId'] ?? cloudDoc['organization_id'],
        if ((cloudDoc['jobTitle'] ??
                cloudDoc['jabatan'] ??
                cloudDoc['job_title']) !=
            null)
          'jobTitle':
              cloudDoc['jobTitle'] ??
              cloudDoc['jabatan'] ??
              cloudDoc['job_title'],
        if ((cloudDoc['divisi'] ?? cloudDoc['jabatan']) != null)
          'divisi': cloudDoc['divisi'] ?? cloudDoc['jabatan'],
      };

      await _local.saveUser(normalizedNim, userDoc);
    }

    return _local.memberFromMap(userDoc);
  }

  Future<void> createUser({
    required String nama,
    required String nim,
    required String divisi,
    required String role,
    required String password,
    String? jobTitle,
  }) async {
    final normalizedNim = nim.trim();
    final existing = _local.findLocalUserByNim(normalizedNim);
    if (existing != null) {
      throw Exception('NIM sudah terdaftar.');
    }

    final nowIso = DateTime.now().toIso8601String();
    final localDoc = <String, dynamic>{
      'nama': nama.trim(),
      'nim': normalizedNim,
      'divisi': divisi.trim(),
      'role': _local.normalizeRole(role),
      'password': hashPassword(password),
      'qrCodeValue': QrService.generateQrData(normalizedNim),
      'isSynced': false,
      'createdAt': nowIso,
      'updatedAt': nowIso,
      if (jobTitle != null && jobTitle.trim().isNotEmpty)
        'jobTitle': jobTitle.trim(),
    };

    await _local.saveUser(normalizedNim, localDoc);
    _local.enqueuePendingUpsert(normalizedNim);
    await syncUpsertUserInBackground(nim: normalizedNim, userDoc: localDoc);
  }

  Future<MemberModel> updateUser({
    required String nim,
    String? nama,
    String? divisi,
    String? role,
    String? password,
    String? jobTitle,
  }) async {
    final storageKey = _local.resolveLocalStorageKey(nim);
    final raw = storageKey != null ? _local.getRawUser(storageKey) : null;
    final currentDoc = _local.toMap(raw);
    if (currentDoc == null || !_isUserDocument(currentDoc)) {
      throw Exception('User tidak ditemukan.');
    }

    final updatedDoc = Map<String, dynamic>.from(currentDoc);
    if (nama != null && nama.trim().isNotEmpty)
      updatedDoc['nama'] = nama.trim();
    if (divisi != null && divisi.trim().isNotEmpty)
      updatedDoc['divisi'] = divisi.trim();
    if (role != null && role.trim().isNotEmpty)
      updatedDoc['role'] = _local.normalizeRole(role);
    if (password != null && password.trim().isNotEmpty)
      updatedDoc['password'] = hashPassword(password);
    if (jobTitle != null && jobTitle.trim().isNotEmpty)
      updatedDoc['jobTitle'] = jobTitle.trim();

    updatedDoc['isSynced'] = false;
    updatedDoc['updatedAt'] = DateTime.now().toIso8601String();

    final nimStorageKey = (updatedDoc['nim'] ?? '').toString().trim();
    final updatedStorageKey = nimStorageKey.isNotEmpty
        ? nimStorageKey
        : (storageKey ?? nim.trim());

    await _local.saveUser(updatedStorageKey, updatedDoc);
    _local.enqueuePendingUpsert(updatedStorageKey);
    await syncUpsertUserInBackground(
      nim: updatedStorageKey,
      userDoc: updatedDoc,
    );

    return _local.memberFromMap(updatedDoc);
  }

  Future<void> deleteUser(String nim) async {
    final storageKey = _local.resolveLocalStorageKey(nim);
    final raw = storageKey != null ? _local.getRawUser(storageKey) : null;
    final doc = _local.toMap(raw);
    if (doc == null || !_isUserDocument(doc)) {
      throw Exception('User tidak ditemukan.');
    }

    await _local.deleteUser(storageKey!);
    final nimToDelete = (doc['nim'] ?? nim).toString().trim();
    _local.dequeuePendingUpsert(nimToDelete);
    _local.enqueuePendingDelete(nimToDelete);
    deleteUserFromCloudInBackground(nimToDelete);
  }

  Future<List<MemberModel>> getAllUsers() async {
    return _local.getAllUsers();
  }

  Future<void> syncPendingUserChanges() async {
    if (!await _isOnline()) return;

    final upserts = _local.getPendingUpsertNims();
    for (final nim in upserts) {
      final storageKey = _local.resolveLocalStorageKey(nim);
      if (storageKey == null) {
        _local.dequeuePendingUpsert(nim);
        continue;
      }
      final raw = _local.getRawUser(storageKey);
      final doc = _local.toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        _local.dequeuePendingUpsert(nim);
        continue;
      }
      final synced = await _remote.upsertUserToCloud(toCloudPayload(doc));
      if (synced) _local.dequeuePendingUpsert(nim);
    }

    final deletes = _local.getPendingDeleteNims();
    for (final nim in deletes) {
      final deleted = await _remote.deleteUserFromCloud(nim);
      if (deleted) _local.dequeuePendingDelete(nim);
    }
  }

  Future<void> normalizeStoredRoles() async {
    var localChanged = false;
    for (final entry in _local.getAllRawUsers().entries) {
      final doc = _local.toMap(entry.value);
      if (doc == null) continue;

      final normalizedRole = _local.normalizeRole(
        (doc['role'] ?? '').toString(),
      );
      if (normalizedRole != doc['role']) {
        doc['role'] = normalizedRole;
        doc['isSynced'] = false;
        doc['updatedAt'] = DateTime.now().toIso8601String();

        final storageKey = (doc['nim'] ?? entry.key).toString().trim();
        if (storageKey.isEmpty) continue;
        await _local.saveUser(storageKey, doc);
        _local.enqueuePendingUpsert(storageKey);
        localChanged = true;
      }
    }

    if (await _isOnline()) {
      await _remote.normalizeRolesInCloud(_local.normalizeRole);
    }
  }

  Future<void> syncUpsertUserInBackground({
    required String nim,
    required Map<String, dynamic> userDoc,
  }) async {
    try {
      _local.enqueuePendingUpsert(nim);
      if (!await _isOnline()) return;

      final synced = await _remote.upsertUserToCloud(toCloudPayload(userDoc));
      if (!synced) return;

      final localDoc = Map<String, dynamic>.from(userDoc)
        ..['isSynced'] = true
        ..['updatedAt'] = DateTime.now().toIso8601String();

      final nimStorageKey = (localDoc['nim'] ?? '').toString().trim();
      final storageKey = nimStorageKey.isNotEmpty ? nimStorageKey : nim;
      await _local.saveUser(storageKey, localDoc);
      _local.dequeuePendingUpsert(storageKey);
      _local.dequeuePendingUpsert(nim);
    } catch (e) {
      debugPrint('[AuthRepo][syncUpsert] error: $e');
    }
  }

  Future<void> deleteUserFromCloudInBackground(String nim) async {
    try {
      if (!await _isOnline()) return;
      final deleted = await _remote.deleteUserFromCloud(nim);
      if (deleted) _local.dequeuePendingDelete(nim);
    } catch (e) {
      debugPrint('[AuthRepo][syncDelete] error: $e');
    }
  }

  Future<void> updateFcmTokenInBackground(String nim, String token) async {
    await _local.updateFCMToken(nim, token);
    if (await _isOnline()) {
      await _remote.updateUserFCMToken(nim, token);
    }
  }

  Map<String, dynamic> toCloudPayload(Map<String, dynamic> doc) {
    final nim = (doc['nim'] ?? '').toString().trim();
    return <String, dynamic>{
      'nama': doc['nama'],
      'nim': nim,
      'divisi': doc['divisi'],
      'role': _local.normalizeRole((doc['role'] ?? '').toString()),
      'organizationId': doc['organizationId'],
      'jobTitle': doc['jobTitle'],
      'qrCodeValue': doc['qrCodeValue'] ?? doc['qrData'],
      'createdAt': doc['createdAt'],
      'updatedAt': doc['updatedAt'],
      'password': doc['password'] ?? doc['passwordHash'],
      'passwordHash': doc['password'] ?? doc['passwordHash'],
    };
  }

  String hashPassword(String password) {
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

  bool verifyPassword(String inputPassword, String storedPassword) {
    final hashedInput = hashPassword(inputPassword);
    if (storedPassword == hashedInput) return true;
    return storedPassword == inputPassword;
  }

  bool _isUserDocument(Map<String, dynamic> doc) {
    return doc['nim']?.toString().trim().isNotEmpty ?? false;
  }

  MemberModel? verifyCredentialsLocal(String nim, String password) {
    final normalizedNim = nim.trim();
    final userDoc = _local.findLocalUserByNim(normalizedNim);
    if (userDoc == null) throw Exception('Akun tidak ditemukan.');

    final savedPassword = (userDoc['password'] ?? userDoc['passwordHash'] ?? '').toString();
    if (!verifyPassword(password, savedPassword))
      throw Exception('Password salah.');

    return _local.memberFromMap(userDoc);
  }

  Future<bool> _isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((r) => r != ConnectivityResult.none);
  }
}
