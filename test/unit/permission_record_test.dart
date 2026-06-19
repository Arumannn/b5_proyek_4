import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/domain/models/attendance/permission_record.dart';

void main() {
  group('PermissionRecord', () {
    test('toMap includes expected keys and ISO date strings', () {
      final created = DateTime.utc(2024, 1, 2, 3, 4, 5);
      final updated = DateTime.utc(2024, 1, 3, 4, 5, 6);

      final rec = PermissionRecord(
        permissionId: 'p1',
        eventId: 'e1',
        nim: '12345',
        jenisIzin: 'Sakit',
        alasan: 'Sakit flu',
        buktiFotoUrl: 'https://example.com/img.jpg',
        status: 'Pending',
        validatedBy: 'admin',
        isSynced: false,
        createdAt: created,
        updatedAt: updated,
        organizationId: 'org1',
      );

      final map = rec.toMap();

      expect(map['permissionId'], 'p1');
      expect(map['eventId'], 'e1');
      expect(map['nim'], '12345');
      expect(map['jenisIzin'], 'Sakit');
      expect(map['alasan'], 'Sakit flu');
      expect(map['buktiFotoUrl'], 'https://example.com/img.jpg');
      expect(map['status'], 'Pending');
      expect(map['validatedBy'], 'admin');
      expect(map['organizationId'], 'org1');
      expect(map['createdAt'], created.toIso8601String());
      expect(map['updatedAt'], updated.toIso8601String());
    });

    test('fromMap applies defaults and parses dates', () {
      final createdStr = '2024-02-01T10:00:00.000Z';
      final updatedStr = '2024-02-02T11:00:00.000Z';

      final map = {
        'permissionId': 'p2',
        'eventId': 'e2',
        'nim': '67890',
        // jenisIzin intentionally omitted to test default
        'alasan': 'Alasan test',
        'buktiFotoUrl': 'https://cdn.example/img.png',
        'status': 'Approved',
        'validatedBy': 'checker',
        'createdAt': createdStr,
        'updatedAt': updatedStr,
        'organizationId': 'org2',
      };

      final rec = PermissionRecord.fromMap(map);

      expect(rec.permissionId, 'p2');
      expect(rec.eventId, 'e2');
      expect(rec.nim, '67890');
      // default jenisIzin is 'Izin'
      expect(rec.jenisIzin, 'Izin');
      expect(rec.alasan, 'Alasan test');
      expect(rec.buktiFotoUrl, 'https://cdn.example/img.png');
      expect(rec.status, 'Approved');
      expect(rec.validatedBy, 'checker');
      expect(rec.organizationId, 'org2');
      expect(rec.createdAt.toUtc().toIso8601String(), createdStr);
      expect(rec.updatedAt.toUtc().toIso8601String(), updatedStr);
      // fromMap marks records from server as synced
      expect(rec.isSynced, isTrue);
    });

    test('toMap -> fromMap roundtrip preserves key fields', () {
      final rec1 = PermissionRecord(
        permissionId: 'round1',
        eventId: 'eventA',
        nim: '99999',
        jenisIzin: 'Izin',
        alasan: 'Roundtrip',
        buktiFotoUrl: 'https://img/1.png',
        status: 'Pending',
        isSynced: false,
        organizationId: 'orgRound',
      );

      final map = rec1.toMap();
      final rec2 = PermissionRecord.fromMap(map);

      expect(rec2.permissionId, rec1.permissionId);
      expect(rec2.eventId, rec1.eventId);
      expect(rec2.nim, rec1.nim);
      expect(rec2.jenisIzin, rec1.jenisIzin);
      expect(rec2.alasan, rec1.alasan);
      expect(rec2.buktiFotoUrl, rec1.buktiFotoUrl);
      expect(rec2.status, rec1.status);
      expect(rec2.organizationId, rec1.organizationId);
      // created/updated roundtrip via ISO string
      expect(rec2.createdAt.toIso8601String(), rec1.createdAt.toIso8601String());
      expect(rec2.updatedAt.toIso8601String(), rec1.updatedAt.toIso8601String());
    });
  });
}
