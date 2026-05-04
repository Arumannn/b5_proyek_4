import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'member_model.g.dart';

@HiveType(typeId: AppConstants.memberTypeId)
class MemberModel extends HiveObject {
  @HiveField(0)
  final String memberId; // Legacy key, nilainya disamakan dengan nim.

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

  MemberModel({
    String? memberId,
    required this.nama,
    required String nim,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrCodeValue,
    this.fcmToken,
  })  : nim = nim.trim(),
        memberId = (memberId ?? nim).trim();

  Map<String, dynamic> toMap() {
    return {
      'memberId': nim,
      'nama': nama,
      'nim': nim,
      'divisi': divisi,
      'role': role,
      'qrCodeValue': qrCodeValue,
      'fcmToken': fcmToken,
      // password TIDAK disertakan
    };
  }

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    final nim = map['nim']?.toString() ?? map['memberId']?.toString() ?? '';
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
    );
  }

  MemberModel copyWith({
    String? memberId,
    String? nama,
    String? nim,
    String? divisi,
    String? role,
    String? password,
    String? qrCodeValue,
    String? fcmToken,
  }) {
    final nextNim = (nim ?? this.nim).trim();
    return MemberModel(
      memberId: memberId ?? nextNim,
      nama: nama ?? this.nama,
      nim: nextNim,
      divisi: divisi ?? this.divisi,
      role: role ?? this.role,
      password: password ?? this.password,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() => 'MemberModel(nim: $nim, nama: $nama, role: $role)';
}