import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'member_model.g.dart';

/// Model data untuk anggota organisasi PRASASTI.
///
/// ATURAN KEAMANAN:
/// - Field [password] HANYA disimpan di Hive lokal — TIDAK pernah dikirim ke cloud.
/// - Gunakan [toMap()] untuk sync ke MongoDB — password otomatis dikecualikan.
/// - [qrData] adalah string yang di-encode ke QR Code, formatnya: "PRASASTI:{nim}"
@HiveType(typeId: AppConstants.memberTypeId) // typeId: 0
class MemberModel extends HiveObject {
  @HiveField(0)
  final String nim; // Identifier unik akun

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String divisi;

  @HiveField(3)
  final String role; // Gunakan AppConstants.roleAdmin atau AppConstants.roleMember

  @HiveField(4)
  final String password; // Disimpan lokal saja — TIDAK dikirim ke cloud

  @HiveField(5)
  final String qrData; // Format: "PRASASTI:{nim}"

  @HiveField(6)
  final String memberId; // UUID unik sebagai primary key

  @HiveField(7)
  String? fcmToken; // FCM token untuk push notification

  // UPDATE CONSTRUCTOR:
  MemberModel({
    required this.nim,
    required this.nama,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrData,
    required this.memberId,  // ← TAMBAH
    this.fcmToken,           // ← TAMBAH
  });

  // UPDATE toMap():
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'nim': nim,
      'divisi': divisi,
      'role': role,
      'qrData': qrData,
      'memberId': memberId,    // ← TAMBAH
      'fcmToken': fcmToken,    // ← TAMBAH
    };
  }

  // UPDATE fromMap():
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      nim: map['nim']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      divisi: map['divisi']?.toString() ?? '',
      role: map['role']?.toString() ?? AppConstants.roleMember,
      password: map['password']?.toString() ?? '',
      qrData: map['qrData']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',      // ← TAMBAH
      fcmToken: map['fcmToken']?.toString(),            // ← TAMBAH
    );
  }

  // UPDATE copyWith():
  MemberModel copyWith({
    String? nim,
    String? nama,
    String? divisi,
    String? role,
    String? password,
    String? qrData,
    String? memberId,    // ← TAMBAH
    String? fcmToken,    // ← TAMBAH
  }) {
    return MemberModel(
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      divisi: divisi ?? this.divisi,
      role: role ?? this.role,
      password: password ?? this.password,
      qrData: qrData ?? this.qrData,
      memberId: memberId ?? this.memberId,        // ← TAMBAH
      fcmToken: fcmToken ?? this.fcmToken,        // ← TAMBAH
    );
  }

  @override
  String toString() {
    return 'MemberModel(nim: $nim, nama: $nama, '
        'divisi: $divisi, role: $role)';
  }
}