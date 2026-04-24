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
  final String memberId; // memberId (= nim) anggota

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  String status; // 'Hadir', 'Terlambat', 'Izin', 'Sakit', 'Alpha'

  @HiveField(5)
  bool isManualOverride; // true jika diubah paksa Admin/Manager

  @HiveField(6)
  String? overrideBy; // memberId yang melakukan override

  @HiveField(7)
  bool isSynced;

  @HiveField(8)
  final String compositeKey; // '${eventId}_${memberId}' — ANTI-DUPLIKAT

  @HiveField(9)
  String? permissionId; // ID izin terkait jika status = 'Izin' atau 'Sakit'

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  AttendanceRecord({
    required this.recordId,
    required this.eventId,
    required this.memberId,
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
    required String memberId,
    String status = 'Hadir',
  }) {
    return AttendanceRecord(
      recordId: recordId,
      eventId: eventId,
      memberId: memberId,
      timestamp: DateTime.now(),
      status: status,
      isManualOverride: false,
      isSynced: false,
      compositeKey: '${eventId}_$memberId',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'eventId': eventId,
      'memberId': memberId,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'isManualOverride': isManualOverride,
      'overrideBy': overrideBy,
      'compositeKey': compositeKey,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      recordId: map['recordId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? map['nim']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'].toString())
          : DateTime.now(),
      status: map['status']?.toString() ?? 'Hadir',
      isManualOverride: map['isManualOverride'] == true,
      overrideBy: map['overrideBy']?.toString(),
      isSynced: true,
      compositeKey: map['compositeKey']?.toString() ??
          '${map['eventId']}_${map['memberId'] ?? map['nim']}',
    );
  }

  @override
  String toString() =>
      'AttendanceRecord(recordId: $recordId, memberId: $memberId, '
      'status: $status, compositeKey: $compositeKey)';
}