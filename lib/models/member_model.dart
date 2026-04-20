import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'member_model.g.dart';

/// Model data untuk anggota organisasi PRASASTI.
///
/// ATURAN KEAMANAN:
/// - Field [password] HANYA disimpan di Hive lokal — TIDAK pernah dikirim ke cloud.
/// - Gunakan [toMap()] untuk sync ke MongoDB — password otomatis dikecualikan.
/// - [qrData] adalah string yang di-encode ke QR Code, formatnya: "PRASASTI:{memberId}"
@HiveType(typeId: AppConstants.memberTypeId) // typeId: 0
class MemberModel extends HiveObject {
  @HiveField(0)
  final String memberId; // UUID unik — basis dari QR Code

  @HiveField(1)
  final String nama;

  @HiveField(2)
  final String nim;

  @HiveField(3)
  final String divisi;

  @HiveField(4)
  final String role; // Gunakan AppConstants.roleAdmin atau AppConstants.roleMember

  @HiveField(5)
  final String password; // Disimpan lokal saja — TIDAK dikirim ke cloud

  @HiveField(6)
  final String qrData; // Format: "PRASASTI:{memberId}"

  MemberModel({
    required this.memberId,
    required this.nama,
    required this.nim,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrData,
  });

  // ─── Konversi ke Map untuk MongoDB Atlas ────────────────────
  // PENTING: password TIDAK dimasukkan — hanya disimpan lokal di Hive.
  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'nama': nama,
      'nim': nim,
      'divisi': divisi,
      'role': role,
      'qrData': qrData,
    };
  }

  // ─── Parse dari response MongoDB Atlas ──────────────────────
  // Digunakan saat fallback login dari cloud (Week 8 Auth).
  // Password dari cloud tidak ada — gunakan string kosong sebagai placeholder.
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      memberId: map['memberId']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      nim: map['nim']?.toString() ?? '',
      divisi: map['divisi']?.toString() ?? '',
      role: map['role']?.toString() ?? AppConstants.roleMember,
      password: map['password']?.toString() ?? '', // Kosong jika dari cloud
      qrData: map['qrData']?.toString() ?? '',
    );
  }

  // ─── CopyWith (berguna saat update data member) ──────────────
  MemberModel copyWith({
    String? memberId,
    String? nama,
    String? nim,
    String? divisi,
    String? role,
    String? password,
    String? qrData,
  }) {
    return MemberModel(
      memberId: memberId ?? this.memberId,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      divisi: divisi ?? this.divisi,
      role: role ?? this.role,
      password: password ?? this.password,
      qrData: qrData ?? this.qrData,
    );
  }

  @override
  String toString() {
    return 'MemberModel(memberId: $memberId, nama: $nama, nim: $nim, '
        'divisi: $divisi, role: $role)';
  }
}