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
  final String? parentEventId; // null = event utama, non-null = sub event
  bool isSynced; // false = belum diupload ke MongoDB Atlas

  EventModel({
    required this.eventId,
    required this.nama,
    required this.jenis,
    required this.tanggal,
    required this.createdBy,
    this.parentEventId,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'nama': nama,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'createdBy': createdBy,
      'parentEventId': parentEventId,
      'isSynced': isSynced,
    };
  }

  factory EventModel.fromMap(Map<dynamic, dynamic> map) {
    return EventModel(
      eventId: (map['eventId'] ?? '').toString(),
      nama: (map['nama'] ?? '').toString(),
      jenis: (map['jenis'] ?? 'Kegiatan').toString(),
      tanggal: DateTime.tryParse((map['tanggal'] ?? '').toString()) ?? DateTime.now(),
      createdBy: (map['createdBy'] ?? 'system').toString(),
      parentEventId: map['parentEventId']?.toString(),
      isSynced: map['isSynced'] == true,
    );
  }

  EventModel copyWith({
    String? eventId,
    String? nama,
    String? jenis,
    DateTime? tanggal,
    String? createdBy,
    String? parentEventId,
    bool? isSynced,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      tanggal: tanggal ?? this.tanggal,
      createdBy: createdBy ?? this.createdBy,
      parentEventId: parentEventId ?? this.parentEventId,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}