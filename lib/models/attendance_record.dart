import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'attendance_record.g.dart';

/// Model untuk record absensi anggota di sebuah event.
///
/// KUNCI ANTI-DUPLIKASI — [compositeKey]:
/// - Format: '${eventId}_${nim}'
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
  final String nim;

  @HiveField(3)
  final DateTime timestamp; // Waktu scan dilakukan

  @HiveField(4)
  bool isSynced; // false = pending upload ke cloud

  /// Composite key = '${eventId}_${nim}'
  /// WAJIB unik per kombinasi event-member.
  /// Dijadikan unique index di MongoDB Atlas untuk anti-duplikasi multi-perangkat.
  @HiveField(5)
  final String compositeKey;

  // TAMBAH 4 FIELD INI:
  @HiveField(6)
  final String memberId; // NIM atau memberId member yang absen

  @HiveField(7)
  String status; // 'hadir', 'terlambat', 'izin', 'sakit', 'alpha'

  @HiveField(8)
  bool isManualOverride; // true = admin ubah manual status

  @HiveField(9)
  final String? overrideBy; // memberId admin yang override (null jika scan biasa)

  // UPDATE CONSTRUCTOR:
  AttendanceRecord({
    required this.recordId,
    required this.eventId,
    required this.nim,
    required this.timestamp,
    this.isSynced = false,
    required this.compositeKey,
    required this.memberId,           // ← TAMBAH
    this.status = 'hadir',            // ← TAMBAH (default hadir)
    this.isManualOverride = false,    // ← TAMBAH (default false)
    this.overrideBy,                  // ← TAMBAH
  });

  // UPDATE factory create():
  factory AttendanceRecord.create({
    required String recordId,
    required String eventId,
    required String nim,
    String status = 'hadir',          // ← TAMBAH parameter
  }) {
    return AttendanceRecord(
      recordId: recordId,
      eventId: eventId,
      nim: nim,
      timestamp: DateTime.now(),
      isSynced: false,
      compositeKey: '${eventId}_$nim',
      memberId: nim,                  // ← TAMBAH (sama dengan nim)
      status: status,                 // ← TAMBAH
      isManualOverride: false,        // ← TAMBAH
    );
  }

  // UPDATE toMap():
  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'eventId': eventId,
      'nim': nim,
      'timestamp': timestamp.toIso8601String(),
      'compositeKey': compositeKey,
      'memberId': memberId,                       // ← TAMBAH
      'status': status,                           // ← TAMBAH
      'isManualOverride': isManualOverride,       // ← TAMBAH
      'overrideBy': overrideBy,                   // ← TAMBAH
    };
  }

  // UPDATE fromMap():
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['recordId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      isSynced: true,
      compositeKey: map['compositeKey']?.toString() ??
          '${map['eventId']}_${map['nim']}',
      memberId: map['memberId']?.toString() ?? '',              // ← TAMBAH
      status: map['status']?.toString() ?? 'hadir',             // ← TAMBAH
      isManualOverride: map['isManualOverride'] == true,        // ← TAMBAH
      overrideBy: map['overrideBy']?.toString(),                // ← TAMBAH
    );
  }

  // ─── Konversi ke Map untuk MongoDB Atlas ────────────────────
  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'eventId': eventId,
      'nim': nim,
      'timestamp': timestamp.toIso8601String(),
      'compositeKey': compositeKey, // Dipakai untuk unique index di Atlas
    };
  }

  // ─── Parse dari response MongoDB Atlas ──────────────────────
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['recordId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
        nim: map['nim']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      isSynced: true,
      compositeKey: map['compositeKey']?.toString() ??
          '${map['eventId']}_${map['nim']}',
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(recordId: $recordId, eventId: $eventId, '
        'nim: $nim, isSynced: $isSynced, compositeKey: $compositeKey)';
  }
}