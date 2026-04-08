// ============================================================
// ATTENDANCE RECORD — Implementasi Penuh: Week 8
// ============================================================
//
// compositeKey adalah KUNCI ANTI-DUPLIKASI:
//   compositeKey = '${eventId}_${memberId}'
//
// Field ini akan dijadikan unique index di MongoDB Atlas
// untuk mencegah duplikasi dari multi-perangkat.
//
// TODO Week 8: Tambahkan @HiveType(typeId: 2), extends HiveObject,
//   @HiveField annotations, toMap(), factory fromMap()

/// Model untuk record absensi anggota di sebuah event.
///
/// isSynced = false → record tersimpan di Hive, belum dikirim ke cloud.
/// isSynced = true  → record sudah berhasil diupload ke MongoDB Atlas.
class AttendanceRecord {
  final String recordId; // UUID
  final String eventId;
  final String memberId;
  final DateTime timestamp;
  bool isSynced;

  /// Composite key = '${eventId}_${memberId}'
  /// WAJIB unik — satu anggota hanya boleh absen sekali per event.
  final String compositeKey;

  AttendanceRecord({
    required this.recordId,
    required this.eventId,
    required this.memberId,
    required this.timestamp,
    this.isSynced = false,
    required this.compositeKey,
  });

  // TODO Week 8: Implementasi toMap() dan factory fromMap()
  // TODO Week 8: Tambahkan @HiveType(typeId: 2) annotations
}