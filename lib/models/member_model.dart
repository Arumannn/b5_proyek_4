import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'member_model.g.dart';

@HiveType(typeId: AppConstants.memberTypeId)
class MemberModel extends HiveObject {
  @HiveField(0)
  final String memberId; // UUID unik (saat ini = nim)

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String nim;

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
    required this.memberId,
    required this.nama,
    required this.nim,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrCodeValue,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
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
    final nim = map['nim']?.toString() ?? '';
    final normalizedNim = nim.trim();
    return MemberModel(
      // Konsistensi domain: memberId disamakan dengan nim di seluruh app.
      memberId: normalizedNim,
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
    return MemberModel(
      memberId: memberId ?? this.memberId,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      divisi: divisi ?? this.divisi,
      role: role ?? this.role,
      password: password ?? this.password,
      qrCodeValue: qrCodeValue ?? this.qrCodeValue,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() =>
      'MemberModel(memberId: $memberId, nim: $nim, nama: $nama, role: $role)';
}