import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'permission_record.g.dart';

@HiveType(typeId: AppConstants.permissionTypeId)
class PermissionRecord extends HiveObject {
  @HiveField(0)
  final String permissionId;

  @HiveField(1)
  final String eventId;

  @HiveField(2)
  final String nim;

  @HiveField(3)
  final String jenisIzin; // 'Sakit' atau 'Izin'

  @HiveField(4)
  final String alasan; // Pastikan backend menambah ini di DBML!

  @HiveField(5)
  String? buktiFotoPath;

  @HiveField(6)
  String? buktiFotoUrl;

  @HiveField(7)
  String status;

  @HiveField(8)
  String? validatedBy;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  PermissionRecord({
    required this.permissionId,
    required this.eventId,
    required this.nim,
    required this.jenisIzin,
    required this.alasan,
    this.buktiFotoPath,
    this.buktiFotoUrl,
    this.status = 'Pending',
    this.validatedBy,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'permissionId': permissionId,
      'eventId': eventId,
      'nim': nim,
      'jenisIzin': jenisIzin,
      'alasan': alasan,
      'buktiFotoUrl': buktiFotoUrl,
      'status': status,
      'validatedBy': validatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PermissionRecord.fromMap(Map<String, dynamic> map) {
    return PermissionRecord(
      permissionId: map['permissionId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      jenisIzin: map['jenisIzin']?.toString() ?? 'Izin',
      alasan: map['alasan']?.toString() ?? '',
      buktiFotoUrl: map['buktiFotoUrl']?.toString(),
      status: map['status']?.toString() ?? 'Pending',
      validatedBy: map['validatedBy']?.toString(),
      isSynced: true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'].toString()) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'].toString()) : DateTime.now(),
    );
  }
}