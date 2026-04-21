import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'event_model.g.dart';

/// Model data untuk event/kegiatan organisasi PRASASTI.
///
/// ALUR DATA:
/// - Dibuat oleh Admin → disimpan ke Hive lokal (isSynced = false)
/// - SyncManager otomatis upload ke MongoDB Atlas saat online (isSynced = true)
@HiveType(typeId: AppConstants.eventTypeId) // typeId: 1
class EventModel extends HiveObject {
  @HiveField(0)
  final String eventId; // UUID unik

  @HiveField(1)
  final String nama; // Nama event, contoh: "Rapat Bulanan Desember"

  @HiveField(2)
  final String jenis; // Gunakan AppConstants.eventTypes: 'Rapat','Acara','Kegiatan','Lainnya'

  @HiveField(3)
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