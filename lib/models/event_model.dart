// ============================================================
// EVENT MODEL — Implementasi Penuh: Week 8
// ============================================================
//
// TODO Week 8: Tambahkan @HiveType(typeId: 1), extends HiveObject,
//   @HiveField annotations, toMap(), factory fromMap()

/// Model data untuk event/kegiatan organisasi.
class EventModel {
  final String eventId; // UUID unik
  final String nama;
  final String jenis; // 'Rapat', 'Acara', 'Kegiatan', 'Lainnya'
  final DateTime tanggal;
  final String createdBy; // memberId Admin yang membuat event
  bool isSynced; // false = belum diupload ke MongoDB Atlas

  EventModel({
    required this.eventId,
    required this.nama,
    required this.jenis,
    required this.tanggal,
    required this.createdBy,
    this.isSynced = false,
  });

  // TODO Week 8: Implementasi toMap() dan factory fromMap()
  // TODO Week 8: Tambahkan @HiveType(typeId: 1) annotations
}