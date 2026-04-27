import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'event_model.g.dart';

@HiveType(typeId: AppConstants.eventTypeId)
class EventModel extends HiveObject {
  @HiveField(0)
  final String eventId;

  @HiveField(1)
  final String? parentEventId; // null = Main Event, ada = Sub-Event

  @HiveField(2)
  final String nama;

  @HiveField(3)
  final String jenis;

  @HiveField(4)
  final DateTime tanggal;

  @HiveField(5)
  final String? deskripsi;

  @HiveField(6)
  final List<String> targetPeserta;

  @HiveField(7)
  final String createdBy;

  @HiveField(8)
  bool isSynced;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime? jamMulai;

  EventModel({
    required this.eventId,
    this.parentEventId,
    required this.nama,
    required this.jenis,
    required this.tanggal,
    this.deskripsi,
    List<String>? targetPeserta,
    required this.createdBy,
    this.isSynced = false,
    DateTime? createdAt,
    this.jamMulai,
  })  : targetPeserta = targetPeserta ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'parentEventId': parentEventId,
      'nama': nama,
      'jenis': jenis,
      'tanggal': tanggal.toIso8601String(),
      'deskripsi': deskripsi,
      'targetPeserta': targetPeserta,
      'createdBy': createdBy,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'jamMulai': jamMulai?.toIso8601String(),
    };
  }

  factory EventModel.fromMap(Map<dynamic, dynamic> map) {
    List<String> parsePeserta(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return EventModel(
      eventId: (map['eventId'] ?? '').toString(),
      parentEventId: map['parentEventId']?.toString(),
      nama: (map['nama'] ?? '').toString(),
      jenis: (map['jenis'] ?? 'Kegiatan').toString(),
      tanggal: DateTime.tryParse((map['tanggal'] ?? '').toString()) ??
          DateTime.now(),
      deskripsi: map['deskripsi']?.toString(),
      targetPeserta: parsePeserta(map['targetPeserta']),
      createdBy: (map['createdBy'] ?? 'system').toString(),
      isSynced: map['isSynced'] == true,
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      jamMulai: map['jamMulai'] != null
          ? DateTime.tryParse(map['jamMulai'].toString())
          : null,
    );
  }

  EventModel copyWith({
    String? eventId,
    String? parentEventId,
    String? nama,
    String? jenis,
    DateTime? tanggal,
    String? deskripsi,
    List<String>? targetPeserta,
    String? createdBy,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? jamMulai,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      parentEventId: parentEventId ?? this.parentEventId,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      tanggal: tanggal ?? this.tanggal,
      deskripsi: deskripsi ?? this.deskripsi,
      targetPeserta: targetPeserta ?? this.targetPeserta,
      createdBy: createdBy ?? this.createdBy,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      jamMulai: jamMulai ?? this.jamMulai,
    );
  }
}