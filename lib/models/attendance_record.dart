import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'attendance_record.g.dart';

@HiveType(typeId: AppConstants.attendanceTypeId)
class AttendanceRecord extends HiveObject {
  @HiveField(0)
  final String recordId;

  @HiveField(1)
  final String eventId;

  @HiveField(2)
  final String nim;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  String status; // 'Hadir', 'Terlambat', 'Izin', 'Sakit', 'Alpha'

  @HiveField(5)
  bool isManualOverride; // true jika diubah paksa Executive/Manager

  @HiveField(6)
  String? overrideBy; // NIM petugas yang melakukan override

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  final String compositeKey; // '${eventId}_${nim}' — ANTI-DUPLIKAT

  @HiveField(9)
  String? permissionId; // ID izin terkait jika status = 'Izin' atau 'Sakit'

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  AttendanceRecord({
    required this.recordId,
    required this.eventId,
    required this.nim,
    required this.timestamp,
    this.status = 'Hadir',
    this.isManualOverride = false,
    this.overrideBy,
    this.isSynced = false,
    required this.compositeKey,
    this.permissionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory AttendanceRecord.create({
    required String recordId,
    required String eventId,
    required String nim,
    String status = 'Hadir',
  }) {
    return AttendanceRecord(
      recordId: recordId,
      eventId: eventId,
      nim: nim,
      timestamp: DateTime.now(),
      status: status,
      isManualOverride: false,
      isSynced: false,
      compositeKey: '${eventId}_$nim',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'eventId': eventId,
      'nim': nim,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'isManualOverride': isManualOverride,
      'overrideBy': overrideBy,
      'compositeKey': compositeKey,
      'permissionId': permissionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['recordId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      status: map['status']?.toString() ?? 'Hadir',
      isManualOverride: map['isManualOverride'] == true,
      overrideBy: map['overrideBy']?.toString(),
      isSynced: true,
      compositeKey: map['compositeKey']?.toString() ??
          '${map['eventId']}_${map['nim']}',
      permissionId: map['permissionId']?.toString(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'].toString())
          : null,
    );
  }

  @override
  String toString() =>
      'AttendanceRecord(recordId: $recordId, nim: $nim, '
      'status: $status, compositeKey: $compositeKey)';
}