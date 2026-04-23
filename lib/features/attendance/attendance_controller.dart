import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/utils/qr_service.dart';
import '../../models/attendance_record.dart';
import '../../models/member_model.dart';

enum AttendanceResult {
  successHadir,
  successTerlambat,
  duplicate,
  memberNotFound,
  eventNotFound,
  error,
}

class AttendanceController {
  static final AttendanceController instance =
      AttendanceController._internal();
  AttendanceController._internal();

  final ValueNotifier<bool> isProcessing = ValueNotifier(false);
  final ValueNotifier<AttendanceResult?> lastResult = ValueNotifier(null);
  // Nama member yang terakhir berhasil scan — untuk ditampilkan di UI
  final ValueNotifier<String?> lastScannedName = ValueNotifier(null);

  /// Merekam absensi dari hasil scan QR.
  ///
  /// [eventId] — ID event yang sedang berjalan.
  /// [scannedQrValue] — nilai raw dari QR Code yang di-scan.
  Future<AttendanceResult> recordAttendance({
    required String eventId,
    required String scannedQrValue,
  }) async {
    if (isProcessing.value) return AttendanceResult.error;
    isProcessing.value = true;
    lastResult.value = null;

    try {
      // 1. Validasi format QR (harus diawali "PRASASTI:")
      final nim = QrService.parseNim(scannedQrValue);
      if (nim == null) {
        lastResult.value = AttendanceResult.memberNotFound;
        return AttendanceResult.memberNotFound;
      }

      // 2. Cari member berdasarkan qrCodeValue di Hive
      MemberModel? member;
      for (final m in HiveService.members.values) {
        if (m.qrCodeValue == scannedQrValue) {
          member = m;
          break;
        }
      }
      if (member == null) {
        lastResult.value = AttendanceResult.memberNotFound;
        return AttendanceResult.memberNotFound;
      }

      // 3. Cek event ada
      final event = HiveService.events.get(eventId);
      if (event == null) {
        lastResult.value = AttendanceResult.eventNotFound;
        return AttendanceResult.eventNotFound;
      }

      // 4. Buat compositeKey & cek duplikasi di Hive
      final compositeKey = '${eventId}_${member.memberId}';
      final isDuplicate = HiveService.attendance.values
          .any((r) => r.compositeKey == compositeKey);
      if (isDuplicate) {
        lastResult.value = AttendanceResult.duplicate;
        return AttendanceResult.duplicate;
      }

      // 5. Tentukan status: Hadir atau Terlambat
      //    Batas: 15 menit setelah hari & jam event (pakai tengah malam hari event)
      final now = DateTime.now();
      final eventDay =
          DateTime(event.tanggal.year, event.tanggal.month, event.tanggal.day);
      final lateThreshold = eventDay.add(const Duration(minutes: 15));
      final isLate = now.isAfter(lateThreshold);
      final status = isLate ? 'Terlambat' : 'Hadir';

      // 6. Simpan record ke Hive (offline-first, isSynced=false)
      final record = AttendanceRecord.create(
        recordId: const Uuid().v4(),
        eventId: eventId,
        memberId: member.memberId,
        status: status,
      );
      await HiveService.attendance.add(record);

      lastScannedName.value = member.nama;
      final result = isLate
          ? AttendanceResult.successTerlambat
          : AttendanceResult.successHadir;
      lastResult.value = result;
      debugPrint(
          '[Attendance] ✅ ${member.nama} — $status (compositeKey: $compositeKey)');
      return result;
    } catch (e, st) {
      debugPrint('[Attendance] Error: $e\n$st');
      lastResult.value = AttendanceResult.error;
      return AttendanceResult.error;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Ambil semua record kehadiran untuk satu event
  List<AttendanceRecord> getAttendanceByEvent(String eventId) {
    return HiveService.attendance.values
        .where((r) => r.eventId == eventId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Ambil semua record kehadiran untuk satu member
  List<AttendanceRecord> getAttendanceByMember(String memberId) {
    return HiveService.attendance.values
        .where((r) => r.memberId == memberId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Fitur override manual oleh Admin / Manager
  Future<bool> overrideAttendanceStatus({
    required String recordId,
    required String newStatus,
    required String overrideById,
  }) async {
    try {
      // Cari record absensi berdasarkan recordId di Hive
      final record = HiveService.attendance.values.firstWhere(
        (r) => r.recordId == recordId,
        orElse: () => throw Exception('Record tidak ditemukan'),
      );

      // Update atribut sesuai aturan brief Tahap 2
      record.status = newStatus;
      record.isManualOverride = true;
      record.overrideBy = overrideById;
      record.isSynced = false;

      // Simpan perubahan
      await record.save();
      debugPrint('[Attendance] Override sukses: Record $recordId menjadi $newStatus oleh $overrideById');
      return true;
    } catch (e) {
      debugPrint('[Attendance] Error override status: $e');
      return false;
    }
  }

  /// Fitur auto-generate "Alpha" di akhir acara
  Future<void> generateAlphaRecords(String eventId) async {
    try {
      // Ambil data event
      final event = HiveService.events.get(eventId);
      if (event == null) {
        debugPrint('[Attendance] Error generate Alpha: Event tidak ditemukan');
        return;
      }

      // Ambil list ID member yang SUDAH ABSEN di event ini (termasuk Izin/Sakit)
      final existingRecords = getAttendanceByEvent(eventId);
      final existingMemberIds = existingRecords.map((r) => r.memberId).toSet();

      // Jika targetPeserta kosong, asumsikan ditargetkan untuk semua member.
      Iterable<MemberModel> targetMembers = HiveService.members.values;
      if (event.targetPeserta.isNotEmpty) {
        targetMembers = targetMembers.where((m) => event.targetPeserta.contains(m.divisi));
      }

      final uuid = const Uuid();
      int alphaCount = 0;

      for (final member in targetMembers) {
        if (!existingMemberIds.contains(member.memberId)) {
          final alphaRecord = AttendanceRecord.create(
            recordId: uuid.v4(),
            eventId: eventId,
            memberId: member.memberId,
            status: 'Alpha',
          );
          await HiveService.attendance.add(alphaRecord);
          alphaCount++;
        }
      }

      debugPrint('[Attendance] Generate Alpha sukses: $alphaCount member ditandai Alpha untuk event $eventId');
    } catch (e) {
      debugPrint('[Attendance] Error generate Alpha: $e');
    }
  }

  void dispose() {
    isProcessing.dispose();
    lastResult.dispose();
    lastScannedName.dispose();
  }
}