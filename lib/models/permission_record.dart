import 'package:hive/hive.dart';
import '../core/constants/app_constants.dart';

part 'permission_record.g.dart';

/// Model untuk record izin/sakit anggota pada sebuah event.
///
/// WORKFLOW IZIN:
/// 1. Member submit izin via app → isSynced=false
/// 2. SyncManager upload ke MongoDB saat online → isSynced=true
/// 3. Admin validasi izin → status berubah dari 'pending' ke 'approved'/'rejected'
/// 4. Notifikasi FCM dikirim ke Member saat status berubah
///
/// STATUS VALUES:
/// - 'pending': Menunggu validasi admin
/// - 'approved': Disetujui admin
/// - 'rejected': Ditolak admin
///
/// JENIS IZIN:
/// - 'sakit': Izin sakit (perlu bukti foto)
/// - 'izin': Izin umum (opsional bukti foto)
@HiveType(typeId: 3) // typeId: 3 untuk PermissionRecord
class PermissionRecord extends HiveObject {
  @HiveField(0)
  final String permissionId; // UUID unik

  @HiveField(1)
  final String eventId; // ID event yang diizinkan

  @HiveField(2)
  final String memberId; // NIM member yang izin

  @HiveField(3)
  final String jenisIzin; // 'sakit' atau 'izin'

  @HiveField(4)
  final String alasan; // Alasan izin

  @HiveField(5)
  final String? buktiFotoPath; // Path lokal foto bukti (jika ada)

  @HiveField(6)
  final String? buktiFotoUrl; // URL Firebase Storage (setelah upload)

  @HiveField(7)
  String status; // 'pending', 'approved', 'rejected'

  @HiveField(8)
  final String? validatedBy; // memberId admin yang validasi (null jika pending)

  @HiveField(9)
  bool isSynced; // false = belum upload ke cloud

  @HiveField(10)
  final DateTime createdAt; // Waktu submit izin

  @HiveField(11)
  final DateTime? validatedAt; // Waktu admin validasi

  PermissionRecord({
    required this.permissionId,
    required this.eventId,
    required this.memberId,
    required this.jenisIzin,
    required this.alasan,
    this.buktiFotoPath,
    this.buktiFotoUrl,
    this.status = 'pending',
    this.validatedBy,
    this.isSynced = false,
    required this.createdAt,
    this.validatedAt,
  });

  // ─── Factory constructor untuk submit izin baru ──────────────
  factory PermissionRecord.create({
    required String permissionId,
    required String eventId,
    required String memberId,
    required String jenisIzin,
    required String alasan,
    String? buktiFotoPath,
  }) {
    return PermissionRecord(
      permissionId: permissionId,
      eventId: eventId,
      memberId: memberId,
      jenisIzin: jenisIzin,
      alasan: alasan,
      buktiFotoPath: buktiFotoPath,
      status: 'pending',
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  // ─── Konversi ke Map untuk MongoDB Atlas ────────────────────
  Map<String, dynamic> toMap() {
    return {
      'permissionId': permissionId,
      'eventId': eventId,
      'memberId': memberId,
      'jenisIzin': jenisIzin,
      'alasan': alasan,
      'buktiFotoUrl': buktiFotoUrl, // Hanya kirim URL, bukan path lokal
      'status': status,
      'validatedBy': validatedBy,
      'createdAt': createdAt.toIso8601String(),
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }

  // ─── Parse dari response MongoDB Atlas ──────────────────────
  factory PermissionRecord.fromMap(Map<String, dynamic> map) {
    return PermissionRecord(
      permissionId: map['permissionId']?.toString() ?? '',
      eventId: map['eventId']?.toString() ?? '',
      memberId: map['memberId']?.toString() ?? '',
      jenisIzin: map['jenisIzin']?.toString() ?? 'izin',
      alasan: map['alasan']?.toString() ?? '',
      buktiFotoUrl: map['buktiFotoUrl']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      validatedBy: map['validatedBy']?.toString(),
      isSynced: true, // Data dari cloud sudah synced
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
      validatedAt: map['validatedAt'] != null
          ? DateTime.parse(map['validatedAt'].toString())
          : null,
    );
  }

  // ─── CopyWith untuk update status validasi ───────────────────
  PermissionRecord copyWith({
    String? permissionId,
    String? eventId,
    String? memberId,
    String? jenisIzin,
    String? alasan,
    String? buktiFotoPath,
    String? buktiFotoUrl,
    String? status,
    String? validatedBy,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? validatedAt,
  }) {
    return PermissionRecord(
      permissionId: permissionId ?? this.permissionId,
      eventId: eventId ?? this.eventId,
      memberId: memberId ?? this.memberId,
      jenisIzin: jenisIzin ?? this.jenisIzin,
      alasan: alasan ?? this.alasan,
      buktiFotoPath: buktiFotoPath ?? this.buktiFotoPath,
      buktiFotoUrl: buktiFotoUrl ?? this.buktiFotoUrl,
      status: status ?? this.status,
      validatedBy: validatedBy ?? this.validatedBy,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  @override
  String toString() {
    return 'PermissionRecord(permissionId: $permissionId, eventId: $eventId, '
        'memberId: $memberId, jenisIzin: $jenisIzin, status: $status)';
  }
}