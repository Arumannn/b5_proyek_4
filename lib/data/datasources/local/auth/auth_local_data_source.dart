import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';

class AuthLocalDataSource {
  Map<String, dynamic>? findLocalUserByNim(String nim) {
    final normalizedNim = nim.trim();
    final values = HiveService.members.values;

    for (final raw in values) {
      final doc = toMap(raw);
      if (doc == null) continue;

      final savedNim = (doc['nim'] ?? '').toString().trim();
      if (savedNim == normalizedNim) {
        return doc;
      }
    }
    return null;
  }

  String? resolveLocalStorageKey(String nim) {
    final candidate = nim.trim();
    if (candidate.isEmpty) {
      return null;
    }

    if (HiveService.members.containsKey(candidate)) {
      return candidate;
    }

    for (final entry in HiveService.members.toMap().entries) {
      final doc = toMap(entry.value);
      if (doc == null) continue;

      final savedNim = (doc['nim'] ?? '').toString().trim();
      if (savedNim == candidate) {
        return entry.key.toString();
      }
    }

    return null;
  }

  Future<void> saveUser(String storageKey, Map<String, dynamic> doc) async {
    await HiveService.members.put(storageKey, memberFromMap(doc));
  }

  Future<void> deleteUser(String storageKey) async {
    await HiveService.members.delete(storageKey);
  }

  List<MemberModel> getAllUsers() {
    final users = <MemberModel>[];
    for (final raw in HiveService.members.values) {
      final doc = toMap(raw);
      if (doc == null || !_isUserDocument(doc)) {
        continue;
      }
      users.add(memberFromMap(doc));
    }
    users.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    return users;
  }

  Map<dynamic, dynamic> getAllRawUsers() {
    return HiveService.members.toMap();
  }
  
  dynamic getRawUser(String storageKey) {
    return HiveService.members.get(storageKey);
  }

  void enqueuePendingUpsert(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserUpserts.put(normalizedNim, normalizedNim);
  }

  void dequeuePendingUpsert(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserUpserts.delete(normalizedNim);
  }

  void enqueuePendingDelete(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserDeletes.put(normalizedNim, normalizedNim);
  }

  void dequeuePendingDelete(String nim) {
    final normalizedNim = nim.trim();
    if (normalizedNim.isEmpty) {
      return;
    }
    HiveService.pendingUserDeletes.delete(normalizedNim);
  }
  
  List<String> getPendingUpsertNims() {
    return HiveService.pendingUserUpserts.values
        .map((nim) => nim.trim())
        .where((nim) => nim.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<String> getPendingDeleteNims() {
    return HiveService.pendingUserDeletes.values
        .map((nim) => nim.trim())
        .where((nim) => nim.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> updateFCMToken(String nim, String token) async {
      final storageKey = resolveLocalStorageKey(nim);
      if (storageKey == null) return;

      final member = HiveService.members.get(storageKey);
      if (member == null) return;

      member.fcmToken = token;
      await member.save();
  }

  MemberModel memberFromMap(Map<String, dynamic> doc) {
    final parsed = MemberModel.fromMap(doc);
    return parsed.copyWith(
      role: normalizeRole((doc['role'] ?? AppConstants.roleMember).toString()),
    );
  }

  Map<String, dynamic>? toMap(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
    if (raw is MemberModel) {
      return <String, dynamic>{
        'nama': raw.nama,
        'nim': raw.nim,
        'divisi': raw.divisi,
        'role': raw.role,
        'password': raw.password,
        'qrCodeValue': raw.qrCodeValue,
        'fcmToken': raw.fcmToken,
        'organizationId': raw.organizationId,
        'jobTitle': raw.jobTitle,
      };
    }
    return null;
  }

  bool _isUserDocument(Map<String, dynamic> doc) {
    return doc['nim']?.toString().trim().isNotEmpty ?? false;
  }

  String normalizeRole(String rawRole) {
    if (rawRole.trim().isEmpty) return AppConstants.roleMember;
    return rawRole.trim();
  }
}
