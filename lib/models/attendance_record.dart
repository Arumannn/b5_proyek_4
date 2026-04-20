import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'attendance_record.g.dart';

/// Model untuk record absensi anggota di sebuah event.
///
/// KUNCI ANTI-DUPLIKASI — [compositeKey]:
/// - Format: '${eventId}_${memberId}'
/// - Dijadikan unique index di MongoDB Atlas (setup di Week 11)
/// - Dicek di Hive lokal SEBELUM menyimpan untuk cegah double scan
/// - Jika dua perangkat scan anggota yang sama secara offline,
///   SyncManager akan handle gracefully saat sync (error 11000 = duplikat)
///
/// ALUR STATUS:
///   Scan QR → isSynced=false (simpan ke Hive)
///   → Internet tersedia → SyncManager upload → isSynced=true
@HiveType(typeId: AppConstants.attendanceTypeId) // typeId: 2
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String recordId; // UUID unik per record

  @HiveField(1)
  final String eventId;

  @HiveField(2)
  final String memberId;

  @HiveField(3)
  final DateTime timestamp; // Waktu scan dilakukan

  @HiveField(4)
  bool isSynced; // false = pending upload ke cloud

  /// Composite key = '${eventId}_${memberId}'
  /// WAJIB unik per kombinasi event-member.
  /// Dijadikan unique index di MongoDB Atlas untuk anti-duplikasi multi-perangkat.
  @HiveField(5)
  final String compositeKey;

  AttendanceRecord({
    required this.recordId,
    required this.eventId,
    required this.memberId,
    required this.timestamp,
    this.isSynced = false,
    required this.compositeKey,
  });

  // ─── Factory constructor (cara standar membuat record baru) ──
  /// Buat AttendanceRecord baru dari hasil scan QR.
  /// compositeKey di-generate otomatis dari eventId + memberId.
  factory AttendanceRecord.create({
    required String recordId,
    required String eventId,
    required String memberId,
  }) {
    return AttendanceRecord(
      recordId: recordId,
      eventId: eventId,
      memberId: memberId,
      timestamp: DateTime.now(),
      isSynced: false,
      compositeKey: '${eventId}_$memberId',
    );
  }

  // ─── Konversi ke Map untuk MongoDB Atlas ────────────────────
  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'eventId': eventId,
      'memberId': memberId,
      'timestamp': timestamp.toIso8601String(),
      'compositeKey': compositeKey, // Dipakai untuk unique index di Atlas
    };
  }

  // ─── Parse dari response MongoDB Atlas ──────────────────────
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['recordId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      isSynced: true,
      compositeKey: map['compositeKey']?.toString() ??
          '${map['eventId']}_${map['memberId']}',
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(recordId: $recordId, eventId: $eventId, '
        'memberId: $memberId, isSynced: $isSynced, compositeKey: $compositeKey)';
  }
}