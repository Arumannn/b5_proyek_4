import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'member_model.g.dart';

@HiveType(typeId: AppConstants.memberTypeId)
class MemberModel extends HiveObject {

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String nim;

  String get identifier => nim;

  @HiveField(3)
  final String divisi;

  @HiveField(4)
  final String role;

  @HiveField(5)
  final String password; // TIDAK dikirim ke cloud

  @HiveField(6)
  final String qrCodeValue; // nilai QR Code pada lanyard

  @HiveField(7)
  String? fcmToken; // token FCM perangkat aktif

  @HiveField(8)
  final String? organizationId;

  @HiveField(9)
  final String? jobTitle;

  MemberModel({
    required this.nama,
    required String nim,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrCodeValue,
    this.fcmToken,
    this.organizationId,
    this.jobTitle,
  })  : nim = nim.trim();

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'nim': nim,
      'divisi': divisi,
      'role': role,
      'password': password,
      'qrCodeValue': qrCodeValue,
      'fcmToken': fcmToken,
      'organizationId': organizationId,
      'jobTitle': jobTitle,
      // password TIDAK disertakan
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    final nim = map['nim']?.toString() ?? '';
    final normalizedNim = nim.trim();
    return MemberModel(
      nama: map['nama']?.toString() ?? '',
      nim: normalizedNim,
      divisi: map['divisi']?.toString() ?? '',
      role: map['role']?.toString() ?? AppConstants.roleMember,
      password: map['password']?.toString() ?? '',
      // support nama field lama 'qrData' untuk backward compat
      qrCodeValue: map['qrCodeValue']?.toString() ??
          map['qrData']?.toString() ?? '',
      fcmToken: map['fcmToken']?.toString(),
      organizationId: map['organizationId']?.toString(),
      jobTitle: map['jobTitle']?.toString(),
    );
  }

  MemberModel copyWith({
    String? nama,
    String? nim,
    String? divisi,
    String? role,
    String? password,
    String? qrCodeValue,
    String? fcmToken,
    String? organizationId,
    String? jobTitle,
  }) {
    final nextNim = (nim ?? this.nim).trim();
    return MemberModel(
      nama: nama ?? this.nama,
      nim: nextNim,
      divisi: divisi ?? this.divisi,
      role: role ?? this.role,
      password: password ?? this.password,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      fcmToken: fcmToken ?? this.fcmToken,
      organizationId: organizationId ?? this.organizationId,
      jobTitle: jobTitle ?? this.jobTitle,
    );
  }

  @override
  String toString() => 'MemberModel(nim: $nim, nama: $nama, role: $role, jobTitle: $jobTitle, orgId: $organizationId)';
}