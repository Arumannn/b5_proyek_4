import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/core/utils/qr_service.dart';
import 'package:b5_proyek_4/features/attendance/attendance_controller.dart';
import 'package:b5_proyek_4/models/attendance_record.dart';
import 'package:b5_proyek_4/models/event_model.dart';
import 'package:b5_proyek_4/models/member_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  final controller = AttendanceController.instance;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return Directory.systemTemp.path;
    });

    await HiveService.init();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await HiveService.members.clear();
    await HiveService.events.clear();
    await HiveService.attendance.clear();
    controller.lastResult.value = null;
    controller.lastScannedName.value = null;
    controller.isProcessing.value = false;
  });

  Future<void> seedMemberAndEvent({
    required String eventId,
    required DateTime tanggalEvent,
    String nim = '241511999',
    String nama = 'Tester',
  }) async {
    final qrValue = QrService.generateQrData(nim);

    await HiveService.members.put(
      nim,
      MemberModel(
        memberId: nim,
        nama: nama,
        nim: nim,
        divisi: 'Core',
        role: 'member',
        password: 'pw',
        qrCodeValue: qrValue,
      ),
    );

    await HiveService.events.put(
      eventId,
      EventModel(
        eventId: eventId,
        nama: 'Event Test',
        jenis: 'Rapat',
        tanggal: tanggalEvent,
        createdBy: 'admin',
      ),
    );
  }

  group('AttendanceController.recordAttendance', () {
    test('mengembalikan memberNotFound jika QR tidak valid', () async {
      final result = await controller.recordAttendance(
        eventId: 'event-1',
        scannedQrValue: 'INVALID_QR',
      );

      expect(result, equals(AttendanceResult.memberNotFound));
      expect(controller.lastResult.value, equals(AttendanceResult.memberNotFound));
    });

    test('mengembalikan eventNotFound jika event tidak ada', () async {
      final nim = '241511111';
      await HiveService.members.put(
        nim,
        MemberModel(
          memberId: nim,
          nama: 'No Event',
          nim: nim,
          divisi: 'Core',
          role: 'member',
          password: 'pw',
          qrCodeValue: QrService.generateQrData(nim),
        ),
      );

      final result = await controller.recordAttendance(
        eventId: 'missing-event',
        scannedQrValue: QrService.generateQrData(nim),
      );

      expect(result, equals(AttendanceResult.eventNotFound));
    });

    test('berhasil hadir untuk event masa depan dan menyimpan record', () async {
      await seedMemberAndEvent(
        eventId: 'event-future',
        tanggalEvent: DateTime.now().add(const Duration(days: 1)),
        nim: '241511123',
        nama: 'Member Hadir',
      );

      final result = await controller.recordAttendance(
        eventId: 'event-future',
        scannedQrValue: QrService.generateQrData('241511123'),
      );

      expect(result, equals(AttendanceResult.successHadir));
      expect(controller.lastScannedName.value, equals('Member Hadir'));
      expect(HiveService.attendance.values.length, equals(1));
      expect(HiveService.attendance.values.first.status, equals('Hadir'));
    });

    test('scan kedua dengan member & event sama menjadi duplicate', () async {
      await seedMemberAndEvent(
        eventId: 'event-dup',
        tanggalEvent: DateTime.now().add(const Duration(days: 1)),
        nim: '241511124',
      );

      final qr = QrService.generateQrData('241511124');
      final first = await controller.recordAttendance(
        eventId: 'event-dup',
        scannedQrValue: qr,
      );
      final second = await controller.recordAttendance(
        eventId: 'event-dup',
        scannedQrValue: qr,
      );

      expect(first, equals(AttendanceResult.successHadir));
      expect(second, equals(AttendanceResult.duplicate));
      expect(HiveService.attendance.values.length, equals(1));
    });

    test('event lampau menghasilkan status terlambat', () async {
      await seedMemberAndEvent(
        eventId: 'event-past',
        tanggalEvent: DateTime.now().subtract(const Duration(days: 1)),
        nim: '241511125',
      );

      final result = await controller.recordAttendance(
        eventId: 'event-past',
        scannedQrValue: QrService.generateQrData('241511125'),
      );

      expect(result, equals(AttendanceResult.successTerlambat));
      expect(HiveService.attendance.values.first.status, equals('Terlambat'));
    });
  });

  group('AttendanceController query helpers', () {
    test('getAttendanceByEvent sort ascending timestamp', () async {
      await HiveService.attendance.addAll([
        AttendanceRecord(
          recordId: 'r2',
          eventId: 'event-1',
          memberId: 'm2',
          timestamp: DateTime(2026, 4, 23, 10, 0),
          compositeKey: 'event-1_m2',
        ),
        AttendanceRecord(
          recordId: 'r1',
          eventId: 'event-1',
          memberId: 'm1',
          timestamp: DateTime(2026, 4, 23, 9, 0),
          compositeKey: 'event-1_m1',
        ),
      ]);

      final results = controller.getAttendanceByEvent('event-1');

      expect(results.map((r) => r.recordId).toList(), equals(['r1', 'r2']));
    });

    test('getAttendanceByMember sort descending timestamp', () async {
      await HiveService.attendance.addAll([
        AttendanceRecord(
          recordId: 'r-old',
          eventId: 'e1',
          memberId: 'member-1',
          timestamp: DateTime(2026, 4, 22, 10, 0),
          compositeKey: 'e1_member-1',
        ),
        AttendanceRecord(
          recordId: 'r-new',
          eventId: 'e2',
          memberId: 'member-1',
          timestamp: DateTime(2026, 4, 23, 10, 0),
          compositeKey: 'e2_member-1',
        ),
      ]);

      final results = controller.getAttendanceByMember('member-1');

      expect(results.map((r) => r.recordId).toList(), equals(['r-new', 'r-old']));
    });
  });
}
