import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/attendance_local_data_source.dart';
import '../data/attendance_remote_data_source.dart';
import '../../../models/attendance_record.dart';
import '../../../models/member_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/qr_service.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/enums/status_enums.dart';

class AttendanceResultData {
  final String status; // 'successHadir', 'successTerlambat', 'duplicate', dsb (mirip enum)
  final String? scannedName;
  final String? failureReason;

  AttendanceResultData({
    required this.status,
    this.scannedName,
    this.failureReason,
  });
}

class AttendanceRepository {
  final AttendanceLocalDataSource _local;
  final AttendanceRemoteDataSource _remote;

  bool _isPreloadingMembers = false;

  AttendanceRepository(this._local, this._remote);

  Future<AttendanceResultData> recordAttendance({
    required String eventId,
    required String scannedQrValue,
  }) async {
    try {
      final normalizedScan = scannedQrValue.trim();
      if (normalizedScan.isEmpty) {
        return AttendanceResultData(
          status: 'memberNotFound',
          failureReason: 'QR kosong atau tidak terbaca',
        );
      }

      final nim = _extractIdentifierFromScan(normalizedScan);
      if (nim.isEmpty) {
        return AttendanceResultData(
          status: 'memberNotFound',
          failureReason: 'Identifier QR tidak dapat diparse',
        );
      }

      final member = await _resolveMemberForScan(
        scannedQrValue: normalizedScan,
        nimFromQr: nim,
      );

      if (member == null) {
        final reason = _isLegacyDummyIdentifier(nim)
            ? 'QR ini berasal dari data dummy lama ($nim). Gunakan QR dari akun member yang tersimpan di sistem saat ini.'
            : 'Member tidak ditemukan di Hive maupun cloud untuk QR: $normalizedScan';
        return AttendanceResultData(
          status: 'memberNotFound',
          failureReason: reason,
        );
      }

      final event = _local.getEvent(eventId);
      if (event == null) {
        return AttendanceResultData(
          status: 'eventNotFound',
          failureReason: 'Event tidak ditemukan: $eventId',
        );
      }

      if (_local.isMainEventWithSubEvents(eventId)) {
        return AttendanceResultData(
          status: 'mainEventHasSubEvents',
          failureReason: 'Main event memiliki sub-event. Lakukan absensi pada sub-event.',
        );
      }

      final compositeKey = '${eventId}_${member.nim}';
      if (_local.hasAttendance(compositeKey)) {
        return AttendanceResultData(
          status: 'duplicate',
          failureReason: 'Duplikat absensi untuk member ${member.nim} pada event $eventId',
        );
      }

      // Validasi tumpang tindih: Cegah absensi jika izin sudah disetujui
      final hasApprovedPermission = HiveService.permissions.values.any(
        (p) => p.eventId == eventId && p.nim == member.nim && p.statusEnum == PermissionStatus.approved,
      );
      if (hasApprovedPermission) {
        return AttendanceResultData(
          status: 'hasPermission',
          failureReason: 'Member telah disetujui untuk Izin/Sakit pada event ini.',
        );
      }

      final now = DateTime.now();
      final baseTime = event.jamMulai ?? event.tanggalMulai;
      final lateThreshold = baseTime.add(const Duration(minutes: 15));
      final isLate = now.isAfter(lateThreshold);
      final status = isLate ? 'Terlambat' : 'Hadir';

      final record = AttendanceRecord.create(
        recordId: const Uuid().v4(),
        eventId: eventId,
        nim: member.nim,
        status: status,
      );

      await _local.saveAttendance(record);

      debugPrint('[AttendanceRepo] ${member.nama} - $status (compositeKey: $compositeKey)');

      return AttendanceResultData(
        status: isLate ? 'successTerlambat' : 'successHadir',
        scannedName: member.nama,
      );
    } catch (e, st) {
      debugPrint('[AttendanceRepo] Error: $e\n$st');
      return AttendanceResultData(
        status: 'error',
        failureReason: 'Exception: $e',
      );
    }
  }

  List<AttendanceRecord> getAttendanceByEvent(String eventId) {
    return _local.getAttendanceByEvent(eventId);
  }

  List<AttendanceRecord> getAttendanceByMember(String nim) {
    return _local.getAttendanceByMember(nim);
  }

  Future<bool> overrideAttendanceStatus({
    required String recordId,
    required String newStatus,
    required String overrideById,
  }) async {
    try {
      final record = _local.getAttendanceByRecordId(recordId);
      if (record == null) throw Exception('Record tidak ditemukan');

      record.status = newStatus;
      record.isManualOverride = true;
      record.overrideBy = overrideById;
      record.isSynced = false;

      await _local.updateAttendance(record);
      debugPrint('[AttendanceRepo] Override sukses: Record $recordId menjadi $newStatus oleh $overrideById');
      return true;
    } catch (e) {
      debugPrint('[AttendanceRepo] Error override status: $e');
      return false;
    }
  }

  Future<void> generateAlphaRecords(String eventId) async {
    try {
      final event = _local.getEvent(eventId);
      if (event == null) {
        debugPrint('[AttendanceRepo] Error generate Alpha: Event tidak ditemukan');
        return;
      }

      if (_local.isMainEventWithSubEvents(eventId)) {
        debugPrint('[AttendanceRepo] Generate Alpha dibatalkan: event $eventId memiliki sub-event.');
        return;
      }

      final existingRecords = _local.getAttendanceByEvent(eventId);
      final existingNims = existingRecords.map((r) => r.nim).toSet();

      Iterable<MemberModel> targetMembers = _local.getAllMembers();
      if (event.targetPeserta.isNotEmpty) {
        targetMembers = targetMembers.where(
          (m) => event.targetPeserta.contains(m.divisi),
        );
      }

      final uuid = const Uuid();
      int alphaCount = 0;

      for (final member in targetMembers) {
        if (!existingNims.contains(member.nim)) {
          final alphaRecord = AttendanceRecord.create(
            recordId: uuid.v4(),
            eventId: eventId,
            nim: member.nim,
            status: 'Alpha',
          );
          await _local.saveAttendance(alphaRecord);
          alphaCount++;
        }
      }

      debugPrint('[AttendanceRepo] Generate Alpha sukses: $alphaCount member ditandai Alpha untuk event $eventId');
    } catch (e) {
      debugPrint('[AttendanceRepo] Error generate Alpha: $e');
    }
  }

  Future<AttendanceResultData> addManualAttendance({
    required String eventId,
    required String nim,
    required String status,
  }) async {
    try {
      final event = _local.getEvent(eventId);
      if (event == null) {
        return AttendanceResultData(status: 'error', failureReason: 'Event tidak ditemukan');
      }

      if (_local.isMainEventWithSubEvents(eventId)) {
        return AttendanceResultData(
          status: 'error',
          failureReason: 'Main event memiliki sub-event. Tambah absensi manual pada sub-event.',
        );
      }

      final member = _local.getMemberByNim(nim);
      if (member == null) {
        return AttendanceResultData(status: 'error', failureReason: 'Member tidak ditemukan');
      }

      final compositeKey = '${eventId}_$nim';
      if (_local.hasAttendance(compositeKey)) {
        return AttendanceResultData(status: 'error', failureReason: 'Absensi sudah ada');
      }

      // Validasi tumpang tindih: Cegah manual absensi jika izin sudah disetujui
      final hasApprovedPermission = HiveService.permissions.values.any(
        (p) => p.eventId == eventId && p.nim == nim && p.statusEnum == PermissionStatus.approved,
      );
      if (hasApprovedPermission) {
        return AttendanceResultData(
          status: 'error',
          failureReason: 'Member telah disetujui untuk Izin/Sakit pada event ini.',
        );
      }

      final record = AttendanceRecord.create(
        recordId: const Uuid().v4(),
        eventId: eventId,
        nim: nim,
        status: status,
      );

      await _local.saveAttendance(record);
      return AttendanceResultData(status: 'success');
    } catch (e) {
      return AttendanceResultData(status: 'error', failureReason: e.toString());
    }
  }

  Future<bool> deleteAttendanceRecord(String recordId) async {
    try {
      final target = _local.getAttendanceByRecordId(recordId);
      if (target == null) throw Exception('Record tidak ditemukan');
      
      final compositeKey = target.compositeKey;
      await _local.deleteAttendance(target);

      // Fire and forget
      _remote.deleteAttendanceFromCloud(compositeKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> preloadMembersFromCloudToHive() async {
    if (_isPreloadingMembers) return;
    _isPreloadingMembers = true;

    try {
      final cloudUsers = await _remote.fetchAllUsers();
      if (cloudUsers.isEmpty) return;

      var insertedOrUpdated = 0;
      for (final raw in cloudUsers) {
        final merged = Map<String, dynamic>.from(raw);
        final nim = (merged['nim'] ?? '').toString().trim();
        if (nim.isEmpty) continue;

        merged['nim'] = nim;
        merged['qrCodeValue'] = (merged['qrCodeValue'] ?? QrService.generateQrData(nim)).toString();

        final model = MemberModel.fromMap(merged);
        await _local.saveMember(model);
        insertedOrUpdated++;
      }
      debugPrint('[AttendanceRepo] preload member done: $insertedOrUpdated cached to Hive');
    } catch (e) {
      debugPrint('[AttendanceRepo] preload member error: $e');
    } finally {
      _isPreloadingMembers = false;
    }
  }

  Future<MemberModel?> _resolveMemberForScan({
    required String scannedQrValue,
    required String nimFromQr,
  }) async {
    final normalizedScan = scannedQrValue.trim();
    final normalizedIdentifier = _normalizeIdentifier(nimFromQr);

    final allMembers = _local.getAllMembers();

    // Priority 1: exact QR match di Hive
    for (final m in allMembers) {
      if (_normalizeIdentifier(m.qrCodeValue) == _normalizeIdentifier(normalizedScan)) {
        return m;
      }
    }

    // Priority 2: fallback by NIM di Hive
    final localByNim = _local.getMemberByNim(nimFromQr) ?? _local.getMemberByNim(normalizedIdentifier);
    if (localByNim != null) {
      if (_normalizeIdentifier(localByNim.qrCodeValue) != _normalizeIdentifier(normalizedScan)) {
        final repaired = localByNim.copyWith(qrCodeValue: normalizedScan);
        await _local.saveMember(repaired);
        return repaired;
      }
      return localByNim;
    }

    // Priority 2b: fallback by normalized identifier di Hive
    for (final m in allMembers) {
      if (_normalizeIdentifier(m.nim) == normalizedIdentifier) {
        if (_normalizeIdentifier(m.qrCodeValue) != _normalizeIdentifier(normalizedScan)) {
          final repaired = m.copyWith(qrCodeValue: normalizedScan);
          await _local.saveMember(repaired);
          return repaired;
        }
        return m;
      }
    }

    // Priority 3: fetch from cloud
    final cloudDoc = await _remote.findUserByNimOrQr(nimFromQr, normalizedIdentifier, normalizedScan);
    if (cloudDoc == null) return null;

    final merged = Map<String, dynamic>.from(cloudDoc)
      ..['nim'] = (cloudDoc['nim'] ?? nimFromQr).toString().trim()
      ..['qrCodeValue'] = (cloudDoc['qrCodeValue'] ?? normalizedScan).toString();

    final cached = MemberModel.fromMap(merged);
    await _local.saveMember(cached);

    return cached;
  }

  String _extractIdentifierFromScan(String rawScan) {
    final parsed = QrService.parseNim(rawScan);
    if (parsed != null && parsed.trim().isNotEmpty) {
      return parsed.trim();
    }

    final upperScan = rawScan.toUpperCase();
    final upperPrefix = AppConstants.qrPrefix.toUpperCase();
    if (upperScan.startsWith(upperPrefix)) {
      return rawScan.substring(AppConstants.qrPrefix.length).trim();
    }

    return rawScan.trim();
  }

  String _normalizeIdentifier(String value) {
    return value.trim().toUpperCase();
  }

  bool _isLegacyDummyIdentifier(String identifier) {
    return _normalizeIdentifier(identifier).startsWith('MEMBER-PRASASTI-');
  }
}
