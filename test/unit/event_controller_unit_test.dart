import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/features/event/event_controller.dart';
import 'package:b5_proyek_4/models/event_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  final controller = EventController.instance;

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
    await HiveService.events.clear();
    controller.clearAllFilters();
    controller.errorMessage.value = null;
    controller.events.value = <EventModel>[];
    await controller.loadEvents(force: true);
  });

  group('EventController basic CRUD', () {
    test('createEvent berhasil untuk event valid', () async {
      final ok = await controller.createEvent(
        nama: '  Rapat Divisi  ',
        tanggal: DateTime.now().add(const Duration(days: 2)),
        jenis: 'Rapat',
        createdBy: 'Executive-1',
      );

      expect(ok, isTrue);
      expect(controller.errorMessage.value, isNull);
      expect(controller.events.value, hasLength(1));
      expect(controller.events.value.first.nama, equals('Rapat Divisi'));
      expect(controller.events.value.first.isSynced, isFalse);
    });

    test('createEvent gagal jika parentEventId tidak ada', () async {
      final ok = await controller.createEvent(
        nama: 'Sub Event',
        tanggal: DateTime.now().add(const Duration(days: 3)),
        parentEventId: 'missing-parent',
      );

      expect(ok, isFalse);
      expect(controller.errorMessage.value, equals('Parent event tidak ditemukan.'));
    });

    test('createEvent berhasil jika parentEventId ada', () async {
      final parent = EventModel(
        eventId: 'parent-1',
        nama: 'Parent',
        jenis: 'Kegiatan',
        tanggal: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      await HiveService.events.put(parent.eventId, parent);
      await controller.loadEvents(force: true);

      final ok = await controller.createEvent(
        nama: 'Sub Event A',
        tanggal: DateTime.now().add(const Duration(days: 2)),
        parentEventId: 'parent-1',
      );

      expect(ok, isTrue);
      final subEvents = controller.getSubEvents('parent-1');
      expect(subEvents, hasLength(1));
      expect(subEvents.first.nama, equals('Sub Event A'));
    });

    test('updateEvent mengubah data dan set isSynced menjadi false', () async {
      final existing = EventModel(
        eventId: 'e-1',
        nama: 'Nama Lama',
        jenis: 'Rapat',
        tanggal: DateTime.now().add(const Duration(days: 2)),
        createdBy: 'Executive',
        isSynced: true,
      );
      await HiveService.events.put(existing.eventId, existing);
      await controller.loadEvents(force: true);

      final ok = await controller.updateEvent(
        existing.copyWith(nama: '  Nama Baru  ', isSynced: true),
      );

      expect(ok, isTrue);
      final updated = HiveService.events.get('e-1');
      expect(updated, isNotNull);
      expect(updated!.nama, equals('Nama Baru'));
      expect(updated.isSynced, isFalse);
    });

    test('deleteEvent menghapus parent dan semua child', () async {
      final root = EventModel(
        eventId: 'root-1',
        nama: 'Root',
        jenis: 'Rapat',
        tanggal: DateTime.now().add(const Duration(days: 1)),
        createdBy: 'Executive',
      );
      final child = EventModel(
        eventId: 'child-1',
        nama: 'Child',
        jenis: 'Acara',
        tanggal: DateTime.now().add(const Duration(days: 2)),
        createdBy: 'Executive',
        parentEventId: 'root-1',
      );
      await HiveService.events.put(root.eventId, root);
      await HiveService.events.put(child.eventId, child);
      await controller.loadEvents(force: true);

      final ok = await controller.deleteEvent('root-1');

      expect(ok, isTrue);
      expect(HiveService.events.containsKey('root-1'), isFalse);
      expect(HiveService.events.containsKey('child-1'), isFalse);
    });
  });

  group('EventController filters', () {
    setUp(() async {
      await HiveService.events.clear();
      final events = <EventModel>[
        EventModel(
          eventId: 'e1',
          nama: 'Rapat Core',
          jenis: 'Rapat',
          tanggal: DateTime(2026, 4, 24),
          createdBy: 'Executive',
        ),
        EventModel(
          eventId: 'e2',
          nama: 'Acara Besar',
          jenis: 'Acara',
          tanggal: DateTime(2026, 4, 25),
          createdBy: 'Executive',
        ),
        EventModel(
          eventId: 'e3',
          nama: 'Kegiatan Divisi',
          jenis: 'Kegiatan',
          tanggal: DateTime(2026, 4, 26),
          createdBy: 'Executive',
        ),
      ];

      for (final e in events) {
        await HiveService.events.put(e.eventId, e);
      }
      await controller.loadEvents(force: true);
    });

    test('setJenisFilter menyaring berdasarkan jenis', () {
      controller.setJenisFilter('Acara');

      expect(controller.events.value, hasLength(1));
      expect(controller.events.value.first.eventId, equals('e2'));
      expect(controller.hasActiveFilters, isTrue);
    });

    test('setDateRangeFilter menyaring berdasarkan tanggal harian', () {
      controller.setDateRangeFilter(
        DateTimeRange(
          start: DateTime(2026, 4, 25, 23, 59),
          end: DateTime(2026, 4, 26, 0, 1),
        ),
      );

      expect(controller.events.value.map((e) => e.eventId), equals(['e2', 'e3']));
    });

    test('setSearchQuery menyaring nama/jenis secara case-insensitive', () {
      controller.setSearchQuery('rapat');

      expect(controller.events.value, hasLength(1));
      expect(controller.events.value.first.eventId, equals('e1'));
    });

    test('clearAllFilters mengembalikan semua data', () {
      controller.setJenisFilter('Rapat');
      controller.setSearchQuery('core');
      expect(controller.events.value, hasLength(1));

      controller.clearAllFilters();

      expect(controller.events.value, hasLength(3));
      expect(controller.hasActiveFilters, isFalse);
    });
  });
}
