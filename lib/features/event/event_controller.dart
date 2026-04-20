import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';

/// Controller untuk CRUD Event secara offline (disimpan ke Hive).
///
/// RULES:
/// - Semua operasi disimpan ke Hive dulu (offline-first)
/// - Validasi: nama wajib diisi, tanggal tidak boleh masa lalu
/// - State di-expose via ValueNotifier — BUKAN setState di View
///
/// Implementasi penuh: Week 9
class EventController {
  static final EventController instance = EventController._internal();
  EventController._internal();

  final ValueNotifier<List<EventModel>> events = ValueNotifier<List<EventModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  bool _hasLoaded = false;

  Future<void> loadEvents({bool force = false}) async {
    if (_hasLoaded && !force) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final box = HiveService.events;
      final loaded = <EventModel>[];

      for (final raw in box.values) {
        if (raw is EventModel) {
          loaded.add(raw);
          continue;
        }

        if (raw is Map) {
          loaded.add(EventModel.fromMap(raw));
        }
      }

      loaded.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      events.value = loaded;
      _hasLoaded = true;
    } catch (e) {
      errorMessage.value = 'Gagal memuat event: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createEvent({
    required String nama,
    required DateTime tanggal,
    String? parentEventId,
    String createdBy = 'unknown',
    String jenis = 'Kegiatan',
  }) async {
    final trimmed = nama.trim();
    if (trimmed.isEmpty) {
      errorMessage.value = 'Nama event wajib diisi.';
      return false;
    }

    if (!AppConstants.eventTypes.contains(jenis)) {
      errorMessage.value = 'Jenis event tidak valid.';
      return false;
    }

    if (_isPastDay(tanggal)) {
      errorMessage.value = 'Tanggal event tidak boleh masa lalu.';
      return false;
    }

    if (parentEventId != null && parentEventId.isNotEmpty) {
      final parentExists = events.value.any((e) => e.eventId == parentEventId);
      if (!parentExists) {
        errorMessage.value = 'Parent event tidak ditemukan.';
        return false;
      }
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final created = EventModel(
        eventId: DateTime.now().microsecondsSinceEpoch.toString(),
        nama: trimmed,
        jenis: jenis,
        tanggal: tanggal,
        createdBy: createdBy,
        parentEventId: parentEventId,
        isSynced: false,
      );

      await HiveService.events.put(created.eventId, created.toMap());

      final updated = List<EventModel>.from(events.value)..add(created);
      updated.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      events.value = updated;
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal menambah event: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEvent(EventModel event) async {
    final trimmed = event.nama.trim();
    if (trimmed.isEmpty) {
      errorMessage.value = 'Nama event wajib diisi.';
      return false;
    }

    if (!AppConstants.eventTypes.contains(event.jenis)) {
      errorMessage.value = 'Jenis event tidak valid.';
      return false;
    }

    if (_isPastDay(event.tanggal)) {
      errorMessage.value = 'Tanggal event tidak boleh masa lalu.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final index = events.value.indexWhere((e) => e.eventId == event.eventId);
      if (index < 0) {
        errorMessage.value = 'Event tidak ditemukan.';
        return false;
      }

      final updated = List<EventModel>.from(events.value);
  final saved = event.copyWith(nama: trimmed, isSynced: false);

  await HiveService.events.put(saved.eventId, saved.toMap());

  updated[index] = saved;
      updated.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      events.value = updated;
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal mengubah event: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final toDelete = events.value
          .where((e) => e.eventId == eventId || e.parentEventId == eventId)
          .map((e) => e.eventId)
          .toList();

      for (final id in toDelete) {
        await HiveService.events.delete(id);
      }

      events.value = events.value
          .where((e) => e.eventId != eventId && e.parentEventId != eventId)
          .toList();
      return true;
    } catch (e) {
      errorMessage.value = 'Gagal menghapus event: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  List<EventModel> getRootEvents() {
    return events.value.where((e) => e.parentEventId == null).toList();
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(date.year, date.month, date.day);
    return inputDay.isBefore(today);
  }
}