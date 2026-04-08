// ============================================================
// MEMBER MODEL — Implementasi Penuh: Week 8
// ============================================================
//
// TODO Week 8 — Langkah implementasi:
// 1. Tambahkan import: import 'package:hive/hive.dart';
// 2. Tambahkan: part 'member_model.g.dart';
// 3. Tambahkan @HiveType(typeId: 0) di atas class
// 4. Ubah class extends HiveObject
// 5. Tambahkan @HiveField(index) di setiap field
// 6. Tambahkan toMap() untuk sync ke MongoDB
// 7. Tambahkan factory fromMap() untuk parse response Atlas
// 8. Jalankan: flutter pub run build_runner build
//    → Generate file member_model.g.dart (TypeAdapter)
// 9. Daftarkan adapter di HiveService.init()

/// Model data untuk anggota organisasi.
///
/// Setiap anggota memiliki QR Code unik berbasis memberId.
/// Password TIDAK boleh dikirim ke cloud — hanya disimpan di Hive lokal.
class MemberModel {
  final String memberId; // UUID — basis dari QR Code
  final String nama;
  final String nim;
  final String divisi;
  final String role; // 'Admin' atau 'Member' (lihat AppConstants)
  final String password; // TODO Week 8: hash password ini!
  final String qrData; // format: "PRASASTI:{memberId}"

  const MemberModel({
    required this.memberId,
    required this.nama,
    required this.nim,
    required this.divisi,
    required this.role,
    required this.password,
    required this.qrData,
  });

  // TODO Week 8: Implementasi toMap() — TANPA field password
  // TODO Week 8: Implementasi factory fromMap()
  // TODO Week 8: Tambahkan @HiveType(typeId: 0) dan @HiveField annotations
}