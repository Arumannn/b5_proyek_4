import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/domain/models/attendance/permission_record.dart';

void main() {
  group('MemberModel', () {
    test('fromMap mendukung field lama qrData', () {
      final member = MemberModel.fromMap({
        'nama': 'Budi',
        'nim': '241511001',
        'divisi': 'Core',
        'role': AppConstants.roleMember,
        'password': 'pw',
        'qrData': 'PRASASTI:241511001',
      });

      expect(member.nim, equals('241511001'));
      expect(member.qrCodeValue, equals('PRASASTI:241511001'));
      expect(member.role, equals(AppConstants.roleMember));
    });

    test('toMap tidak menyertakan password', () {
      final member = MemberModel(
        nama: 'Siti',
        nim: '241511002',
        divisi: 'Event',
        role: AppConstants.roleOrganizer,
        password: 'secret',
        qrCodeValue: 'PRASASTI:241511002',
      );

      final map = member.toMap();

      expect(map['nim'], equals('241511002'));
      expect(map.containsKey('password'), isFalse);
    });
  });

  group('EventModel', () {
    test('toMap/fromMap mempertahankan field penting', () {
      final event = EventModel(
        eventId: 'e-1',
        parentEventId: 'p-1',
        nama: 'Rapat Mingguan',
        jenis: 'Rapat',
        tanggalMulai: DateTime(2026, 4, 22),
        tanggalSelesai: null,
        deskripsi: 'Agenda rutin',
        targetPeserta: const ['Core', 'Media'],
        createdBy: '241511001',
        isSynced: false,
        createdAt: DateTime(2026, 4, 20),
      );

      final map = event.toMap();
      final parsed = EventModel.fromMap(map);

      expect(parsed.eventId, equals('e-1'));
      expect(parsed.parentEventId, equals('p-1'));
      expect(parsed.nama, equals('Rapat Mingguan'));
      expect(parsed.targetPeserta, equals(const ['Core', 'Media']));
      expect(parsed.isSynced, isFalse);
    });

    test('fromMap memberi default saat nilai kosong/tidak valid', () {
      final parsed = EventModel.fromMap({
        'eventId': 'e-2',
        'nama': 'Fallback Date',
        'tanggalMulai': 'invalid-date',
      });

      expect(parsed.jenis, equals('Kegiatan'));
      expect(parsed.createdBy, equals('system'));
      expect(parsed.tanggalMulai, isA<DateTime>());
    });
  });

  group('AttendanceRecord', () {
    test('create membuat compositeKey dengan format event_member', () {
      final record = AttendanceRecord.create(
        recordId: 'r-1',
        eventId: 'e-1',
        nim: '241511003',
      );

      expect(record.compositeKey, equals('e-1_241511003'));
      expect(record.status, equals('Hadir'));
      expect(record.isSynced, isFalse);
    });

    test('fromMap membaca properties dengan benar', () {
      final record = AttendanceRecord.fromMap({
        'recordId': 'r-2',
        'eventId': 'e-1',
        'nim': '241511004',
        'status': 'Izin',
      });

      expect(record.nim, equals('241511004'));
      expect(record.compositeKey, equals('e-1_241511004'));
      expect(record.isSynced, isTrue);
    });
  });

  group('PermissionRecord', () {
    test('fromMap menetapkan default dan menandai synced=true', () {
      final permission = PermissionRecord.fromMap({
        'permissionId': 'p-1',
        'eventId': 'e-1',
        'nim': '241511005',
        'alasan': 'Sakit',
      });

      expect(permission.jenisIzin, equals('Izin'));
      expect(permission.status, equals('Pending'));
      expect(permission.isSynced, isTrue);
    });

    test('toMap hanya mengembalikan payload cloud yang dibutuhkan', () {
      final permission = PermissionRecord(
        permissionId: 'p-2',
        eventId: 'e-2',
        nim: '241511006',
        jenisIzin: 'Sakit',
        alasan: 'Demam',
        buktiFotoPath: '/tmp/img.jpg',
        buktiFotoUrl: 'https://img.example/test.jpg',
        status: 'Approved',
        validatedBy: 'Executive-1',
      );

      final map = permission.toMap();

      expect(map['permissionId'], equals('p-2'));
      expect(map['buktiFotoUrl'], equals('https://img.example/test.jpg'));
      expect(map.containsKey('buktiFotoPath'), isFalse);
    });
  });
}
