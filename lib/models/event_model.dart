import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'event_model.g.dart';

@HiveType(typeId: AppConstants.eventTypeId)
class EventModel extends HiveObject {
  @HiveField(0)
  final String eventId;

  @HiveField(1)
  final String? parentEventId;

  @HiveField(2)
  final String nama;

  @HiveField(3)
  final String jenis;

  @HiveField(4)
  final DateTime tanggalMulai;

  @HiveField(5)
  final DateTime? tanggalSelesai;

  @HiveField(6)
  final String? deskripsi;

  @HiveField(7)
  final List<String> targetPeserta;

  @HiveField(8)
  final String createdBy;

  @HiveField(9)
  bool isSynced;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  final DateTime? jamMulai;

  @HiveField(12)
  final DateTime? jamSelesai;

  @HiveField(13)
  String? lokasi;

  @HiveField(14)
  String statusEvent;

  @HiveField(15)
  final bool requiresInvitation;

  @HiveField(16)
  final String? penyelenggara;

  // ─── BARU: Soft Delete ──────────────────────────────────────
  // null = event aktif. Ada isi = event sudah dihapus (soft delete).
  // JANGAN benar-benar hapus dokumen — biarkan ada supaya perangkat
  // lain yang sedang offline bisa tahu event ini sudah dihapus.
  @HiveField(17)
  DateTime? deletedAt;

  // ─── BARU: Optimistic Concurrency ───────────────────────────
  // Naik +1 setiap kali event diupdate. Dipakai saat push ke MongoDB
  // untuk mendeteksi kalau ada perangkat lain yang sudah mengubah
  // event ini duluan (konflik versi).
  @HiveField(18)
  int version;

  EventModel({
    required this.eventId,
    this.parentEventId,
    required this.nama,
    required this.jenis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.deskripsi,
    List<String>? targetPeserta,
    required this.createdBy,
    this.isSynced = false,
    DateTime? createdAt,
    this.jamMulai,
    this.jamSelesai,
    this.lokasi,
    String? statusEvent,
    this.requiresInvitation = false,
    this.penyelenggara,
    this.deletedAt,
    this.version = 1,
  })  : targetPeserta = targetPeserta ?? [],
        createdAt = createdAt ?? DateTime.now(),
        statusEvent = statusEvent ??
            _calculateInitialStatus(
                DateTime.now(), tanggalMulai, tanggalSelesai, jamMulai, jamSelesai);

  // Apakah event ini sudah dihapus (soft delete)?
  bool get isDeleted => deletedAt != null;

  static String _calculateInitialStatus(DateTime now, DateTime tanggalMulai,
      DateTime? tanggalSelesai, DateTime? jamMulai, DateTime? jamSelesai) {
    final startTime = jamMulai ?? DateTime(
      tanggalMulai.year,
      tanggalMulai.month,
      tanggalMulai.day,
      0, 0, 0,
    );

    DateTime endTime;
    if (jamSelesai != null) {
      endTime = jamSelesai;
    } else if (tanggalSelesai != null) {
      endTime = DateTime(tanggalSelesai.year, tanggalSelesai.month,
          tanggalSelesai.day, 23, 59, 59);
    } else {
      endTime = DateTime(tanggalMulai.year, tanggalMulai.month,
          tanggalMulai.day, 23, 59, 59);
    }

    if (now.isBefore(startTime)) return 'Mendatang';
    if (now.isAfter(endTime)) return 'Selesai';
    return 'Berlangsung';
  }

  void refreshStatus() {
    final expectedStatus = _calculateInitialStatus(
        DateTime.now(), tanggalMulai, tanggalSelesai, jamMulai, jamSelesai);
    if (statusEvent != expectedStatus) {
      statusEvent = expectedStatus;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'parentEventId': parentEventId,
      'nama': nama,
      'jenis': jenis,
      'tanggalMulai': tanggalMulai.toIso8601String(),
      'tanggalSelesai': tanggalSelesai?.toIso8601String(),
      'deskripsi': deskripsi,
      'targetPeserta': targetPeserta,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'jamMulai': jamMulai?.toIso8601String(),
      'jamSelesai': jamSelesai?.toIso8601String(),
      'lokasi': lokasi,
      'statusEvent': statusEvent,
      'requiresInvitation': requiresInvitation,
      'penyelenggara': penyelenggara,
      'deletedAt': deletedAt?.toIso8601String(),
      'version': version,
    };
  }

  factory EventModel.fromMap(Map<dynamic, dynamic> map) {
    List<String> parsePeserta(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    final parsedTanggalMulai =
        DateTime.tryParse((map['tanggalMulai'] ?? '').toString()) ?? DateTime.now();
    final parsedTanggalSelesai =
        DateTime.tryParse((map['tanggalSelesai'] ?? '').toString());
    final parsedJamMulai = map['jamMulai'] != null
        ? DateTime.tryParse(map['jamMulai'].toString())
        : null;
    final parsedJamSelesai = map['jamSelesai'] != null
        ? DateTime.tryParse(map['jamSelesai'].toString())
        : null;
    final parsedDeletedAt = map['deletedAt'] != null
        ? DateTime.tryParse(map['deletedAt'].toString())
        : null;

    return EventModel(
      eventId: (map['eventId'] ?? '').toString(),
      parentEventId: map['parentEventId']?.toString(),
      nama: (map['nama'] ?? '').toString(),
      jenis: (map['jenis'] ?? 'Kegiatan').toString(),
      tanggalMulai: parsedTanggalMulai,
      tanggalSelesai: parsedTanggalSelesai,
      deskripsi: map['deskripsi']?.toString(),
      targetPeserta: parsePeserta(map['targetPeserta']),
      createdBy: (map['createdBy'] ?? 'system').toString(),
      isSynced: map['isSynced'] == true,
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      jamMulai: parsedJamMulai,
      jamSelesai: parsedJamSelesai,
      lokasi: map['lokasi']?.toString(),
      statusEvent: map['statusEvent']?.toString(),
      requiresInvitation: map['requiresInvitation'] == true,
      penyelenggara: map['penyelenggara']?.toString(),
      deletedAt: parsedDeletedAt,
      version: (map['version'] as int?) ?? 1,
    );
  }

  EventModel copyWith({
    String? eventId,
    String? parentEventId,
    String? nama,
    String? jenis,
    DateTime? tanggalMulai,
    DateTime? tanggalSelesai,
    String? deskripsi,
    List<String>? targetPeserta,
    String? createdBy,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? jamMulai,
    DateTime? jamSelesai,
    String? lokasi,
    String? statusEvent,
    bool? requiresInvitation,
    String? penyelenggara,
    DateTime? deletedAt,
    bool clearDeletedAt = false, // pakai ini untuk set deletedAt = null
    int? version,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      parentEventId: parentEventId ?? this.parentEventId,
      nama: nama ?? this.nama,
      jenis: jenis ?? this.jenis,
      tanggalMulai: tanggalMulai ?? this.tanggalMulai,
      tanggalSelesai: tanggalSelesai ?? this.tanggalSelesai,
      deskripsi: deskripsi ?? this.deskripsi,
      targetPeserta: targetPeserta ?? this.targetPeserta,
      createdBy: createdBy ?? this.createdBy,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      jamMulai: jamMulai ?? this.jamMulai,
      jamSelesai: jamSelesai ?? this.jamSelesai,
      lokasi: lokasi ?? this.lokasi,
      statusEvent: statusEvent ?? this.statusEvent,
      requiresInvitation: requiresInvitation ?? this.requiresInvitation,
      penyelenggara: penyelenggara ?? this.penyelenggara,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      version: version ?? this.version,
    );
  }
}