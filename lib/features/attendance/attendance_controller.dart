import 'package:flutter/foundation.dart';

// TODO Week 10: Implementasi penuh AttendanceController
// import '../../models/attendance_record.dart';
// import '../../models/member_model.dart';
// import '../../core/services/hive_service.dart';
// import '../../core/constants/app_constants.dart';

/// Enum hasil operasi scan QR untuk absensi.
enum AttendanceResult {
  success,    // Berhasil — record tersimpan di Hive
  duplicate,  // QR sudah pernah di-scan untuk event ini (double scan)
  memberNotFound, // QR tidak dikenal — bukan anggota terdaftar
  eventNotFound,  // eventId tidak ada di Hive
  error,      // Error tidak terduga
}

/// Controller untuk logika absensi QR Code.
///
/// KUNCI ANTI-DUPLIKASI:
///   compositeKey = '${eventId}_${memberId}'
///   Cek compositeKey di Hive sebelum menyimpan record baru.
///
/// Implementasi penuh: Week 10
class AttendanceController {
  static final AttendanceController instance = AttendanceController._internal();
  AttendanceController._internal();

  final ValueNotifier<bool> isProcessing = ValueNotifier(false);
  final ValueNotifier<AttendanceResult?> lastResult = ValueNotifier(null);

  // TODO Week 10: Implementasi recordAttendance(eventId, scannedQrData)
  // TODO Week 10: Implementasi getAttendanceByEvent(eventId)
  // TODO Week 10: Implementasi getAttendanceByMember(memberId)
}