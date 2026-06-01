import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:b5_proyek_4/core/constants/app_constants.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/features/event/event_controller.dart';
import 'package:b5_proyek_4/models/event_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late final Directory testDocumentsDir;

  final controller = EventController.instance;

  setUpAll(() async {
    testDocumentsDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}event_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    testDocumentsDir.createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return testDocumentsDir.path;
      }
      return testDocumentsDir.path;
    });

    const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');
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
      .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), null);
  });

  setUp(() async {
    await HiveService.events.clear();
    controller.events.value = <EventModel>[];
    controller.errorMessage.value = null;
    controller.isLoading.value = false;
    await controller.loadEvents(force: true);
  });

  group('EventController.loadEvents', () {
    test('memuat event dari Hive dan mengurutkan tanggal ascending', () async {
      final later = DateTime.now().add(const Duration(days: 2));
      final earlier = DateTime.now().add(const Duration(days: 1));

      await HiveService.events.put('e2', EventModel(
        eventId: 'e2',
        nama: 'Event Besok Lusa',
        jenis: 'Rapat',
        tanggalMulai: later,
        tanggalSelesai: later,
        createdBy: 'Executive',
      ));
      await HiveService.events.put('e1', EventModel(
        eventId: 'e1',
        nama: 'Event Besok',
        jenis: 'Rapat',
        tanggalMulai: earlier,
        tanggalSelesai: earlier,
        createdBy: 'Executive',
      ));

      await controller.loadEvents(force: true);

      expect(controller.events.value.length, 2);
      expect(controller.events.value.first.eventId, 'e1');
      expect(controller.events.value.last.eventId, 'e2');
      expect(controller.errorMessage.value, isNull);
      expect(controller.isLoading.value, isFalse);
    });
  });

  group('EventController.createEvent', () {
    test('gagal jika nama kosong', () async {
      final ok = await controller.createEvent(
        nama: '   ',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
      );
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Nama event wajib diisi.');
    });

    test('gagal jika jenis tidak valid', () async {
      final ok = await controller.createEvent(
        nama: 'Event X',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        jenis: 'InvalidJenis',
      );
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Jenis event tidak valid.');
    });

    test('gagal jika tanggal masa lalu', () async {
      final ok = await controller.createEvent(
        nama: 'Event Lama',
        tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Tanggal event tidak boleh masa lalu.');
    });

    test('gagal jika parent event tidak ditemukan', () async {
      final ok = await controller.createEvent(
        nama: 'Sub Event',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        parentEventId: 'missing-parent',
      );
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Parent event tidak ditemukan.');
    });

    test('berhasil membuat event root', () async {
      final ok = await controller.createEvent(
        nama: '  Rapat Besar  ',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        jenis: 'Rapat',
        createdBy: '241511038',
      );

      expect(ok, isTrue);
      expect(controller.errorMessage.value, isNull);
      expect(controller.events.value.length, 1);

      final created = controller.events.value.first;
      expect(created.nama, 'Rapat Besar');
      expect(created.jenis, 'Rapat');
      expect(created.createdBy, '241511038');
      expect(created.parentEventId, isNull);
      expect(created.isSynced, isFalse);

      final saved = HiveService.events.get(created.eventId);
      expect(saved, isNotNull);
      expect(saved!.nama, 'Rapat Besar');
    });

    test('berhasil membuat sub event jika parent ada di Hive', () async {
      final parent = EventModel(
        eventId: 'parent-1',
        nama: 'Parent',
        jenis: 'Kegiatan',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      await HiveService.events.put(parent.eventId, parent);
      await controller.loadEvents(force: true);

      final ok = await controller.createEvent(
        nama: 'Sub Event',
        tanggalMulai: DateTime.now().add(const Duration(days: 2)),
        parentEventId: 'parent-1',
      );

      expect(ok, isTrue);
      final created = controller.events.value.firstWhere(
        (e) => e.parentEventId == 'parent-1',
      );
      expect(created.nama, 'Sub Event');
    });
  });

  group('EventController.updateEvent', () {
    test('gagal jika nama kosong', () async {
      final model = EventModel(
        eventId: 'e1',
        nama: '   ',
        jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      final ok = await controller.updateEvent(model);
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Nama event wajib diisi.');
    });

    test('gagal jika tanggal masa lalu', () async {
      final model = EventModel(
        eventId: 'e1',
        nama: 'Event',
        jenis: 'Rapat',
        tanggalMulai: DateTime.now().subtract(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().subtract(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      final ok = await controller.updateEvent(model);
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Tanggal event tidak boleh masa lalu.');
    });

    test('gagal jika event tidak ditemukan di _allEvents', () async {
      final model = EventModel(
        eventId: 'not-found',
        nama: 'Event',
        jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      final ok = await controller.updateEvent(model);
      expect(ok, isFalse);
      expect(controller.errorMessage.value, 'Event tidak ditemukan.');
    });

    test('berhasil update event, trim nama, dan set isSynced=false', () async {
      final existing = EventModel(
        eventId: 'e1',
        nama: 'Nama Lama',
        jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
        isSynced: true,
      );
      await HiveService.events.put(existing.eventId, existing);
      await controller.loadEvents(force: true);

      final updatedInput = existing.copyWith(nama: '  Nama Baru  ', isSynced: true);
      final ok = await controller.updateEvent(updatedInput);

      expect(ok, isTrue);
      expect(controller.errorMessage.value, isNull);

      final updated = controller.events.value.first;
      expect(updated.nama, 'Nama Baru');
      expect(updated.isSynced, isFalse);

      final saved = HiveService.events.get('e1');
      expect(saved, isNotNull);
      expect(saved!.nama, 'Nama Baru');
      expect(saved.isSynced, isFalse);
    });
  });

  group('EventController.deleteEvent', () {
    test('menghapus root event beserta sub event-nya', () async {
      final root = EventModel(
        eventId: 'root-1', nama: 'Root', jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      final child = EventModel(
        eventId: 'child-1', nama: 'Child', jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
        parentEventId: 'root-1',
      );
      final other = EventModel(
        eventId: 'other-1', nama: 'Other', jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 2)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 2)),
        createdBy: 'Executive',
      );

      await HiveService.events.put(root.eventId, root);
      await HiveService.events.put(child.eventId, child);
      await HiveService.events.put(other.eventId, other);
      await controller.loadEvents(force: true);

      final ok = await controller.deleteEvent('root-1');

      expect(ok, isTrue);
      expect(controller.events.value.length, 1);
      expect(controller.events.value.single.eventId, 'other-1');
      final rootSaved = HiveService.events.get('root-1');
      expect(rootSaved, isNotNull);
      expect(rootSaved!.deletedAt, isNotNull);
      final childSaved = HiveService.events.get('child-1');
      expect(childSaved, isNotNull);
      expect(childSaved!.deletedAt, isNotNull);
      expect(HiveService.events.containsKey('other-1'), isTrue);
    });
  });

  group('EventController.getRootEvents', () {
    test('hanya mengembalikan event dengan parentEventId null', () async {
      await HiveService.events.put('root-1', EventModel(
        eventId: 'root-1', nama: 'Root A', jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      ));
      await HiveService.events.put('child-1', EventModel(
        eventId: 'child-1', nama: 'Child A', jenis: 'Rapat',
        tanggalMulai: DateTime.now().add(const Duration(days: 1)),
        tanggalSelesai: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
        parentEventId: 'root-1',
      ));
      await controller.loadEvents(force: true);

      final roots = controller.getRootEvents();
      expect(roots.length, 1);
      expect(roots.single.eventId, 'root-1');
    });
  });
}