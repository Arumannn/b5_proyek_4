import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/models/member_model.dart';
import 'package:b5_proyek_4/models/event_invitation.dart';
import 'package:b5_proyek_4/features/event/invitation_monitoring_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return Directory.systemTemp.path;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (methodCall) async {
      if (methodCall.method == 'check') return <String>['none'];
      return null;
    });

    await HiveService.init();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  setUp(() async {
    await HiveService.members.clear();
    await HiveService.invitations.clear();
    await HiveService.permissions.clear();
  });

  testWidgets('Shows Cek Izin button for permission requests', (WidgetTester tester) async {
    // Arrange: create member and invitation with permission-request status.
    final member = MemberModel(
      nama: 'Alice',
      nim: 'A1',
      divisi: 'Dev',
      role: 'member',
      password: 'pass',
      qrCodeValue: 'qr',
    );
    await HiveService.members.put(member.nim, member);

    final invitation = EventInvitation(
      invitationId: 'inv-1',
      eventId: 'event-1',
      nim: member.nim,
      responseStatus: 'permission_requested',
      attendanceTime: DateTime.now(),
      invitedBy: 'org',
      invitedAt: DateTime.now(),
    );
    await HiveService.invitations.put(invitation.invitationId, invitation);

    // Act: pump widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: InvitationMonitoringSection(eventId: 'event-1')),
    ));

    await tester.pump();

    // Assert: find 'Cek Izin' button
    expect(find.text('Cek Izin'), findsOneWidget);
  });
}
