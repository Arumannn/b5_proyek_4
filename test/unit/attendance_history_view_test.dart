import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/core/services/mongo_service.dart';
import 'package:b5_proyek_4/features/event/event_controller.dart';
import 'package:b5_proyek_4/features/attendance/attendance_history_view.dart';
import 'package:b5_proyek_4/features/auth/auth_controller.dart';
import 'package:b5_proyek_4/models/attendance_record.dart';
import 'package:b5_proyek_4/models/event_model.dart';
import 'package:b5_proyek_4/models/member_model.dart';
import 'package:b5_proyek_4/models/permission_record.dart';
import 'package:b5_proyek_4/models/event_invitation.dart';
import '../helpers/mock_mongo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  late Directory _tmpDir;

  setUpAll(() async {
    _tmpDir = Directory.systemTemp.createTempSync('hive_history_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      return _tmpDir.path;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (methodCall) async {
      if (methodCall.method == 'check') return <String>['none'];
      return null;
    });

    MongoService.instance = MockMongoService();
    await initializeDateFormatting('id_ID');
    await HiveService.init();
  });

  tearDownAll(() async {
    EventController.instance.stopStatusRefreshTimer();
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    try {
      if (await _tmpDir.exists()) {
        await _tmpDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    EventController.instance.clearAllFilters();
    await HiveService.members.clear();
    await HiveService.events.clear();
    await HiveService.attendance.clear();
    await HiveService.permissions.clear();
    await HiveService.invitations.clear();
  });

  testWidgets('AttendanceHistoryView maps actual and virtual records correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final member = MemberModel(
      nama: 'Test User',
      nim: '241511999',
      divisi: 'Core',
      role: 'member',
      password: 'pw',
      qrCodeValue: 'PRASASTI:241511999',
    );

    // Event 1: Lampau & Hadir (Actual Record)
    final eventPastHadir = EventModel(
      eventId: 'evt-past-hadir',
      nama: 'Event Lampau Hadir',
      jenis: 'Rapat',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 2)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 2)),
      targetPeserta: ['241511999'],
      createdBy: 'exec',
    );

    final recordHadir = AttendanceRecord(
      recordId: 'rec-1',
      eventId: 'evt-past-hadir',
      nim: '241511999',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      status: 'Hadir',
      compositeKey: 'evt-past-hadir_241511999',
    );

    // Event 2: Lampau & Tidak Hadir (Virtual Alpha)
    final eventPastAlpha = EventModel(
      eventId: 'evt-past-alpha',
      nama: 'Event Lampau Alpha',
      jenis: 'Rapat',
      tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
      tanggalSelesai: DateTime.now().subtract(const Duration(days: 1)),
      targetPeserta: ['241511999'],
      createdBy: 'exec',
    );

    // Event 3: Mendatang & Belum Absen (Virtual Belum Absen)
    final eventFuture = EventModel(
      eventId: 'evt-future',
      nama: 'Event Mendatang',
      jenis: 'Rapat',
      tanggalMulai: DateTime.now().add(const Duration(days: 2)),
      tanggalSelesai: DateTime.now().add(const Duration(days: 2)),
      targetPeserta: ['241511999'],
      createdBy: 'exec',
    );

    // Event 4: Lampau & Izin Pending (Virtual Izin Pending)
    final eventPastIzin = EventModel(
      eventId: 'evt-past-izin',
      nama: 'Event Lampau Izin',
      jenis: 'Rapat',
      tanggalMulai: DateTime.now().subtract(const Duration(hours: 12)),
      tanggalSelesai: DateTime.now().subtract(const Duration(hours: 12)),
      targetPeserta: ['241511999'],
      createdBy: 'exec',
    );

    final permPending = PermissionRecord(
      permissionId: 'perm-1',
      eventId: 'evt-past-izin',
      nim: '241511999',
      jenisIzin: 'Izin',
      alasan: 'Acara keluarga',
      status: 'Pending',
    );

    final invitationIzin = EventInvitation(
      eventId: 'evt-past-izin',
      nim: '241511999',
      responseStatus: 'permission_requested',
      attendanceTime: DateTime.now(),
      invitedBy: 'system',
      invitedAt: DateTime.now(),
    );

    await tester.runAsync(() async {
      await HiveService.members.put(member.nim, member);
      await HiveService.events.put(eventPastHadir.eventId, eventPastHadir);
      await HiveService.events.put(eventPastAlpha.eventId, eventPastAlpha);
      await HiveService.events.put(eventFuture.eventId, eventFuture);
      await HiveService.events.put(eventPastIzin.eventId, eventPastIzin);

      await HiveService.attendance.add(recordHadir);
      await HiveService.invitations.put(invitationIzin.compositeKey, invitationIzin);
      await HiveService.permissions.put(permPending.permissionId, permPending);
    });

    AuthController.instance.currentUser.value = member;

    await tester.pumpWidget(MaterialApp(
      home: AttendanceHistoryView(nim: member.nim, showBottomNav: false),
    ));

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Print all rendered Text widgets
    debugPrint('--- RENDERED TEXT WIDGETS ---');
    for (final element in tester.allElements) {
      final widget = element.widget;
      if (widget is Text) {
        debugPrint('Text: "${widget.data}"');
      }
    }
    debugPrint('-----------------------------');

    // Verify events and statuses are rendered
    expect(find.text('Event Lampau Hadir'), findsOneWidget);
    expect(find.text('Event Lampau Alpha'), findsOneWidget);
    expect(find.text('Event Mendatang'), findsOneWidget);
    expect(find.text('Event Lampau Izin'), findsOneWidget);

    expect(find.text('Hadir'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Belum Absen'), findsOneWidget);
    expect(find.text('Izin Pending'), findsOneWidget);

    EventController.instance.stopStatusRefreshTimer();
  });
}
