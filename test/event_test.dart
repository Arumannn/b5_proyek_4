import 'package:flutter_test/flutter_test.dart';

import 'package:b5_proyek_4/core/constants/app_constants.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/features/event/event_controller.dart';
import 'package:b5_proyek_4/models/event_model.dart';

void main() {
	TestWidgetsFlutterBinding.ensureInitialized();

	final controller = EventController.instance;

	setUpAll(() async {
		await HiveService.init();
	});

	tearDownAll(() async {
		await HiveService.closeAll();
	});

	setUp(() async {
		await HiveService.events.clear();
		controller.events.value = <EventModel>[];
		controller.errorMessage.value = null;
		controller.isLoading.value = false;
	});

	group('EventController.loadEvents', () {
		test('memuat event dari Hive dan mengurutkan tanggal ascending', () async {
			final later = DateTime.now().add(const Duration(days: 2));
			final earlier = DateTime.now().add(const Duration(days: 1));

			await HiveService.events.put(
				'e2',
				EventModel(
					eventId: 'e2',
					nama: 'Event Besok Lusa',
					jenis: 'Rapat',
					tanggal: later,
					createdBy: 'admin',
				),
			);
			await HiveService.events.put(
				'e1',
				EventModel(
					eventId: 'e1',
					nama: 'Event Besok',
					jenis: 'Rapat',
					tanggal: earlier,
					createdBy: 'admin',
				),
			);

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
				tanggal: DateTime.now().add(const Duration(days: 1)),
			);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Nama event wajib diisi.');
		});

		test('gagal jika jenis tidak valid', () async {
			final ok = await controller.createEvent(
				nama: 'Event X',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				jenis: 'InvalidJenis',
			);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Jenis event tidak valid.');
		});

		test('gagal jika tanggal masa lalu', () async {
			final ok = await controller.createEvent(
				nama: 'Event Lama',
				tanggal: DateTime.now().subtract(const Duration(days: 1)),
			);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Tanggal event tidak boleh masa lalu.');
		});

		test('gagal jika parent event tidak ditemukan', () async {
			final ok = await controller.createEvent(
				nama: 'Sub Event',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				parentEventId: 'missing-parent',
			);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Parent event tidak ditemukan.');
		});

		test('berhasil membuat event root', () async {
			final ok = await controller.createEvent(
				nama: '  Rapat Besar  ',
				tanggal: DateTime.now().add(const Duration(days: 1)),
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

		test('berhasil membuat sub event jika parent ada di state', () async {
			final parent = EventModel(
				eventId: 'parent-1',
				nama: 'Parent',
				jenis: 'Kegiatan',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
			);
			controller.events.value = <EventModel>[parent];

			final ok = await controller.createEvent(
				nama: 'Sub Event',
				tanggal: DateTime.now().add(const Duration(days: 2)),
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
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
			);

			final ok = await controller.updateEvent(model);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Nama event wajib diisi.');
		});

		test('gagal jika jenis tidak valid', () async {
			final model = EventModel(
				eventId: 'e1',
				nama: 'Event',
				jenis: 'Foo',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
			);

			final ok = await controller.updateEvent(model);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Jenis event tidak valid.');
		});

		test('gagal jika tanggal masa lalu', () async {
			final model = EventModel(
				eventId: 'e1',
				nama: 'Event',
				jenis: AppConstants.eventTypes.first,
				tanggal: DateTime.now().subtract(const Duration(days: 1)),
				createdBy: 'admin',
			);

			final ok = await controller.updateEvent(model);

			expect(ok, isFalse);
			expect(controller.errorMessage.value, 'Tanggal event tidak boleh masa lalu.');
		});

		test('gagal jika event tidak ditemukan di state', () async {
			final model = EventModel(
				eventId: 'not-found',
				nama: 'Event',
				jenis: AppConstants.eventTypes.first,
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
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
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
				isSynced: true,
			);
			controller.events.value = <EventModel>[existing];
			await HiveService.events.put(existing.eventId, existing);

			final updatedInput = existing.copyWith(
				nama: '  Nama Baru  ',
				isSynced: true,
			);

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
				eventId: 'root-1',
				nama: 'Root',
				jenis: 'Rapat',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
			);
			final child = EventModel(
				eventId: 'child-1',
				nama: 'Child',
				jenis: 'Rapat',
				tanggal: DateTime.now().add(const Duration(days: 1)),
				createdBy: 'admin',
				parentEventId: 'root-1',
			);
			final other = EventModel(
				eventId: 'other-1',
				nama: 'Other',
				jenis: 'Rapat',
				tanggal: DateTime.now().add(const Duration(days: 2)),
				createdBy: 'admin',
			);

			controller.events.value = <EventModel>[root, child, other];
			await HiveService.events.put(root.eventId, root);
			await HiveService.events.put(child.eventId, child);
			await HiveService.events.put(other.eventId, other);

			final ok = await controller.deleteEvent('root-1');

			expect(ok, isTrue);
			expect(controller.events.value.length, 1);
			expect(controller.events.value.single.eventId, 'other-1');
			expect(HiveService.events.containsKey('root-1'), isFalse);
			expect(HiveService.events.containsKey('child-1'), isFalse);
			expect(HiveService.events.containsKey('other-1'), isTrue);
		});
	});

	group('EventController.getRootEvents', () {
		test('hanya mengembalikan event dengan parentEventId null', () {
			controller.events.value = <EventModel>[
				EventModel(
					eventId: 'root-1',
					nama: 'Root A',
					jenis: 'Rapat',
					tanggal: DateTime.now().add(const Duration(days: 1)),
					createdBy: 'admin',
				),
				EventModel(
					eventId: 'child-1',
					nama: 'Child A',
					jenis: 'Rapat',
					tanggal: DateTime.now().add(const Duration(days: 1)),
					createdBy: 'admin',
					parentEventId: 'root-1',
				),
			];

			final roots = controller.getRootEvents();
			expect(roots.length, 1);
			expect(roots.single.eventId, 'root-1');
		});
	});
}
