import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/core/utils/qr_service.dart';
import 'package:b5_proyek_4/models/member_model.dart';
import 'package:b5_proyek_4/models/event_model.dart';
import 'package:b5_proyek_4/models/attendance_record.dart';
import 'package:b5_proyek_4/core/constants/app_constants.dart';

void main() {

  // ─── Week 7: QrService Tests ────────────────────────────────
  group('QrService — Week 7 Basic Validation', () {
    test('generateQrData menghasilkan format PRASASTI yang benar', () {
      const nim = '241511123';
      final result = QrService.generateQrData(nim);
      expect(result, equals('PRASASTI:241511123'));
    });

    test('parseNim berhasil extract NIM dari QR valid', () {
      const qrData = 'PRASASTI:241511999';
      final result = QrService.parseNim(qrData);
      expect(result, equals('241511999'));
    });

    test('parseNim return null untuk format QR tidak valid', () {
      const qrData = 'INVALID:something';
      final result = QrService.parseNim(qrData);
      expect(result, isNull);
    });

    test('parseNim return null untuk empty nim', () {
      const qrData = 'PRASASTI:';
      final result = QrService.parseNim(qrData);
      expect(result, isNull);
    });

    test('isValidQr return true untuk QR PRASASTI yang valid', () {
      expect(QrService.isValidQr('PRASASTI:abc123'), isTrue);
    });

    test('isValidQr return false untuk QR asing', () {
      expect(QrService.isValidQr('random_qr_data'), isFalse);
    });

    test('isValidQr return false untuk string kosong', () {
      expect(QrService.isValidQr(''), isFalse);
    });
  });

  // ─── Week 8: Model Tests ─────────────────────────────────────
  group('MemberModel — Week 8 Sub-Tahap A', () {
    test('MemberModel bisa diinstansiasi dengan semua field', () {
      final member = MemberModel(
        memberId: '241511035',        // ← wajib ada
        nim: '241511035',
        nama: 'Ahmad Riyadh',
        divisi: 'Frontend',
        role: AppConstants.roleAdmin,
        password: 'password123',
        qrCodeValue: 'PRASASTI:241511035', // ← bukan qrData
      );
      expect(member.nim, equals('241511035'));
      expect(member.nama, equals('Ahmad Riyadh'));
      expect(member.role, equals(AppConstants.roleAdmin));
    });

    test('MemberModel.toMap() TIDAK mengandung password', () {
      final member = MemberModel(
        memberId: '241511035',
        nim: '241511035',
        nama: 'Ahmad Riyadh',
        divisi: 'Frontend',
        role: AppConstants.roleAdmin,
        password: 'rahasia123',
        qrCodeValue: 'PRASASTI:241511035',
      );
      final map = member.toMap();
      expect(map.containsKey('password'), isFalse,
          reason: 'Password tidak boleh dikirim ke cloud!');
      expect(map['nim'], equals('241511035'));
      expect(map['nama'], equals('Ahmad Riyadh'));
    });

    test('MemberModel.fromMap() bisa parse dari Map', () {
      final map = {
        'memberId': '241511038',
        'nama': 'Arman Yusuf',
        'nim': '241511038',
        'divisi': 'Backend',
        'role': AppConstants.roleMember,
        'qrCodeValue': 'PRASASTI:241511038',
      };
      final member = MemberModel.fromMap(map);
      expect(member.nim, equals('241511038'));
      expect(member.nama, equals('Arman Yusuf'));
      expect(member.role, equals(AppConstants.roleMember));
    });

    test('MemberModel qrCodeValue menggunakan format PRASASTI yang benar', () {
      const nim = '241511123';
      final qrCodeValue = QrService.generateQrData(nim);
      final member = MemberModel(
        memberId: nim,
        nim: nim,
        nama: 'Test Member',
        divisi: 'Test',
        role: AppConstants.roleMember,
        password: 'test',
        qrCodeValue: qrCodeValue, // ← bukan qrData
      );
      expect(member.qrCodeValue, equals('PRASASTI:241511123'));
      expect(QrService.isValidQr(member.qrCodeValue), isTrue);
      expect(QrService.parseNim(member.qrCodeValue), equals(nim));
    });
  });

  group('EventModel — Week 8 Sub-Tahap A', () {
    test('EventModel bisa diinstansiasi dengan semua field', () {
      final now = DateTime.now();
      final event = EventModel(
        eventId: 'event-001',
        nama: 'Rapat Bulanan',
        jenis: 'Rapat',
        tanggal: now,
        createdBy: 'uuid-001',
      );
      expect(event.eventId, equals('event-001'));
      expect(event.nama, equals('Rapat Bulanan'));
      expect(event.isSynced, isFalse,
          reason: 'Event baru harus isSynced=false (offline-first)');
    });

    test('EventModel.toMap() menghasilkan Map yang benar', () {
      final tanggal = DateTime(2025, 12, 25);
      final event = EventModel(
        eventId: 'event-001',
        nama: 'Acara Natal',
        jenis: 'Acara',
        tanggal: tanggal,
        createdBy: 'uuid-admin',
      );
      final map = event.toMap();
      expect(map['eventId'], equals('event-001'));
      expect(map['nama'], equals('Acara Natal'));
      expect(map['jenis'], equals('Acara'));
      expect(map.containsKey('tanggal'), isTrue);
    });

    test('EventModel.fromMap() bisa parse dari Map', () {
      final map = {
        'eventId': 'event-002',
        'nama': 'Kegiatan Baksos',
        'jenis': 'Kegiatan',
        'tanggal': DateTime(2025, 11, 10).toIso8601String(),
        'createdBy': 'uuid-admin',
        'isSynced': true, // ← tambahkan ini agar sesuai ekspektasi
      };
      final event = EventModel.fromMap(map);
      expect(event.eventId, equals('event-002'));
      expect(event.isSynced, isTrue,
          reason: 'Event dari cloud harus isSynced=true');
    });

    test('EventModel jenis harus salah satu dari AppConstants.eventTypes', () {
      for (final jenis in AppConstants.eventTypes) {
        final event = EventModel(
          eventId: 'event-test',
          nama: 'Test Event',
          jenis: jenis,
          tanggal: DateTime.now(),
          createdBy: 'uuid-admin',
        );
        expect(AppConstants.eventTypes.contains(event.jenis), isTrue);
      }
    });
  });

  group('AttendanceRecord — Week 8 Sub-Tahap A', () {
    test('AttendanceRecord.create() generate compositeKey yang benar', () {
      final record = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: '241511001', // ← bukan nim
      );
      expect(record.compositeKey, equals('event-001_241511001'),
          reason: 'compositeKey harus format: eventId_memberId');
      expect(record.isSynced, isFalse,
          reason: 'Record baru harus isSynced=false (offline-first)');
    });

    test('compositeKey berbeda untuk event berbeda', () {
      final record1 = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: '241511001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-002',
        eventId: 'event-002',
        memberId: '241511001',
      );
      expect(record1.compositeKey, isNot(equals(record2.compositeKey)));
    });

    test('compositeKey berbeda untuk member berbeda', () {
      final record1 = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: '241511001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-002',
        eventId: 'event-001',
        memberId: '241511002',
      );
      expect(record1.compositeKey, isNot(equals(record2.compositeKey)));
    });

    test('AttendanceRecord.toMap() mengandung compositeKey', () {
      final record = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: '241511001',
      );
      final map = record.toMap();
      expect(map.containsKey('compositeKey'), isTrue);
      expect(map['compositeKey'], equals('event-001_241511001'));
    });

    test('Anti-duplikasi: dua record dengan eventId+memberId sama punya compositeKey sama', () {
      final record1 = AttendanceRecord.create(
        recordId: 'rec-device-A',
        eventId: 'event-001',
        memberId: '241511001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-device-B',
        eventId: 'event-001',
        memberId: '241511001',
      );
      expect(record1.compositeKey, equals(record2.compositeKey));
    });
  });
}