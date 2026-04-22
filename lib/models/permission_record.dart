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
  final String memberId;

  @HiveField(3)
  final String jenisIzin; // 'Sakit' atau 'Izin'

  @HiveField(4)
  final String alasan;

  @HiveField(5)
  String? buktiFotoPath; // path file lokal (sebelum sync)

  @HiveField(6)
  String? buktiFotoUrl; // URL Firebase Storage (setelah sync)

  @HiveField(7)
  String status; // 'Pending', 'Approved', 'Rejected'

  @HiveField(8)
  String? validatedBy; // memberId Admin/Manager yang validasi

  @HiveField(9)
  bool isSynced;

  PermissionRecord({
    required this.permissionId,
    required this.eventId,
    required this.memberId,
    required this.jenisIzin,
    required this.alasan,
    this.buktiFotoPath,
    this.buktiFotoUrl,
    this.status = 'Pending',
    this.validatedBy,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'permissionId': permissionId,
      'eventId': eventId,
      'memberId': memberId,
      'jenisIzin': jenisIzin,
      'alasan': alasan,
      'buktiFotoUrl': buktiFotoUrl,
      'status': status,
      'validatedBy': validatedBy,
    };
  }

  factory PermissionRecord.fromMap(Map<String, dynamic> map) {
    return PermissionRecord(
      permissionId: map['permissionId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      jenisIzin: map['jenisIzin']?.toString() ?? 'Izin',
      alasan: map['alasan']?.toString() ?? '',
      buktiFotoUrl: map['buktiFotoUrl']?.toString(),
      status: map['status']?.toString() ?? 'Pending',
      validatedBy: map['validatedBy']?.toString(),
      isSynced: true,
    );
  }
}