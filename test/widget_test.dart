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
      const memberId = 'member-123';
      final result = QrService.generateQrData(memberId);
      expect(result, equals('PRASASTI:member-123'));
    });

    test('parseMemberId berhasil extract ID dari QR valid', () {
      const qrData = 'PRASASTI:member-abc';
      final result = QrService.parseMemberId(qrData);
      expect(result, equals('member-abc'));
    });

    test('parseMemberId return null untuk format QR tidak valid', () {
      const qrData = 'INVALID:something';
      final result = QrService.parseMemberId(qrData);
      expect(result, isNull);
    });

    test('parseMemberId return null untuk empty memberId', () {
      const qrData = 'PRASASTI:';
      final result = QrService.parseMemberId(qrData);
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
        memberId: 'uuid-001',
        nama: 'Ahmad Riyadh',
        nim: '241511035',
        divisi: 'Frontend',
        role: AppConstants.roleAdmin,
        password: 'password123',
        qrData: 'PRASASTI:uuid-001',
      );
      expect(member.memberId, equals('uuid-001'));
      expect(member.nama, equals('Ahmad Riyadh'));
      expect(member.role, equals('Admin'));
    });

    test('MemberModel.toMap() TIDAK mengandung password', () {
      final member = MemberModel(
        memberId: 'uuid-001',
        nama: 'Ahmad Riyadh',
        nim: '241511035',
        divisi: 'Frontend',
        role: AppConstants.roleAdmin,
        password: 'rahasia123',
        qrData: 'PRASASTI:uuid-001',
      );
      final map = member.toMap();
      expect(map.containsKey('password'), isFalse,
          reason: 'Password tidak boleh dikirim ke cloud!');
      expect(map['memberId'], equals('uuid-001'));
      expect(map['nama'], equals('Ahmad Riyadh'));
    });

    test('MemberModel.fromMap() bisa parse dari Map', () {
      final map = {
        'memberId': 'uuid-002',
        'nama': 'Arman Yusuf',
        'nim': '241511038',
        'divisi': 'Backend',
        'role': 'Member',
        'qrData': 'PRASASTI:uuid-002',
      };
      final member = MemberModel.fromMap(map);
      expect(member.memberId, equals('uuid-002'));
      expect(member.nama, equals('Arman Yusuf'));
      expect(member.role, equals('Member'));
    });

    test('MemberModel qrData menggunakan format PRASASTI yang benar', () {
      const memberId = 'uuid-abc-123';
      final qrData = QrService.generateQrData(memberId);
      final member = MemberModel(
        memberId: memberId,
        nama: 'Test Member',
        nim: '123456789',
        divisi: 'Test',
        role: AppConstants.roleMember,
        password: 'test',
        qrData: qrData,
      );
      expect(member.qrData, equals('PRASASTI:uuid-abc-123'));
      expect(QrService.isValidQr(member.qrData), isTrue);
      expect(QrService.parseMemberId(member.qrData), equals(memberId));
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
        memberId: 'member-001',
      );
      expect(record.compositeKey, equals('event-001_member-001'),
          reason: 'compositeKey harus format: eventId_memberId');
      expect(record.isSynced, isFalse,
          reason: 'Record baru harus isSynced=false (offline-first)');
    });

    test('compositeKey berbeda untuk event berbeda', () {
      final record1 = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: 'member-001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-002',
        eventId: 'event-002', // event berbeda
        memberId: 'member-001', // member sama
      );
      expect(record1.compositeKey, isNot(equals(record2.compositeKey)),
          reason: 'Member yang sama di event berbeda = compositeKey berbeda');
    });

    test('compositeKey berbeda untuk member berbeda', () {
      final record1 = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: 'member-001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-002',
        eventId: 'event-001', // event sama
        memberId: 'member-002', // member berbeda
      );
      expect(record1.compositeKey, isNot(equals(record2.compositeKey)));
    });

    test('AttendanceRecord.toMap() mengandung compositeKey', () {
      final record = AttendanceRecord.create(
        recordId: 'rec-001',
        eventId: 'event-001',
        memberId: 'member-001',
      );
      final map = record.toMap();
      expect(map.containsKey('compositeKey'), isTrue,
          reason: 'compositeKey harus ada di Map untuk unique index MongoDB');
      expect(map['compositeKey'], equals('event-001_member-001'));
    });

    test('Anti-duplikasi: dua record dengan eventId+memberId sama punya compositeKey sama', () {
      // Simulasi dua perangkat scan orang yang sama di event yang sama
      final record1 = AttendanceRecord.create(
        recordId: 'rec-device-A',
        eventId: 'event-001',
        memberId: 'member-001',
      );
      final record2 = AttendanceRecord.create(
        recordId: 'rec-device-B',
        eventId: 'event-001',
        memberId: 'member-001',
      );
      // compositeKey sama → MongoDB unique index akan tolak record kedua saat sync
      expect(record1.compositeKey, equals(record2.compositeKey),
          reason: 'Duplikat terdeteksi dari compositeKey yang sama');
    });
  });
}