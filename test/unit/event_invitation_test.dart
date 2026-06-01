import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/models/event_invitation.dart';
import 'package:b5_proyek_4/core/enums/status_enums.dart';

void main() {
  group('EventInvitation', () {
    test('fromJson parses date strings and defaults', () {
      final map = {
        'invitationId': 'inv1',
        'eventId': 'evt1',
        'nim': '11111',
        'responseStatus': 'approved',
        'responseMessage': 'OK',
        'respondedAt': '2024-05-01T08:00:00.000Z',
        'attendanceStatus': 'hadir',
        'attendanceTime': '2024-05-01T09:00:00.000Z',
        'invitedBy': 'owner',
        'invitedAt': '2024-04-30T12:00:00.000Z',
        'isRequired': true,
        'isSynced': true,
        'organizationId': 'orgX',
      };

      final inv = EventInvitation.fromJson(map);

      expect(inv.invitationId, 'inv1');
      expect(inv.eventId, 'evt1');
      expect(inv.nim, '11111');
      expect(inv.responseStatus, 'approved');
      expect(inv.responseMessage, 'OK');
      expect(inv.respondedAt?.toUtc().toIso8601String(), '2024-05-01T08:00:00.000Z');
      expect(inv.attendanceStatus, 'hadir');
      expect(inv.attendanceTime.toUtc().toIso8601String(), '2024-05-01T09:00:00.000Z');
      expect(inv.invitedBy, 'owner');
      expect(inv.invitedAt.toUtc().toIso8601String(), '2024-04-30T12:00:00.000Z');
      expect(inv.isRequired, isTrue);
      expect(inv.isSynced, isTrue);
      expect(inv.organizationId, 'orgX');

      // enum getters
      expect(inv.responseStatusEnum, InvitationStatus.approved);
      expect(inv.attendanceStatusEnum, AttendanceStatus.hadir);
    });

    test('toJson produces ISO date strings and expected keys', () {
      final invitedAt = DateTime.utc(2023, 3, 4, 5, 6, 7);
      final attendanceTime = DateTime.utc(2023, 3, 5, 6, 7, 8);

      final inv = EventInvitation(
        invitationId: 'inv2',
        eventId: 'evt2',
        nim: '22222',
        responseStatus: 'pending',
        attendanceTime: attendanceTime,
        invitedBy: 'admin',
        invitedAt: invitedAt,
      );

      final map = inv.toJson();

      expect(map['invitationId'], 'inv2');
      expect(map['eventId'], 'evt2');
      expect(map['nim'], '22222');
      expect(map['responseStatus'], 'pending');
      expect(map['attendanceTime'], attendanceTime.toIso8601String());
      expect(map['invitedAt'], invitedAt.toIso8601String());
      expect(map['isRequired'], true);
    });
  });
}
