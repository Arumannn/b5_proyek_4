import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';

/// Controller untuk CRUD Event secara offline (disimpan ke Hive).
///
/// FITUR BARU WEEK 9 SUB-TAHAP B:
/// - Filter berdasarkan jenis event
/// - Filter berdasarkan range tanggal
/// - Search berdasarkan nama event
/// - Smart filtering & sorting
///
/// RULES:
/// - Semua operasi disimpan ke Hive dulu (offline-first)
/// - Validasi: nama wajib diisi, tanggal tidak boleh masa lalu
/// - State di-expose via ValueNotifier — BUKAN setState di View
class EventController {
  static final EventController instance = EventController._internal();
  EventController._internal();

  final ValueNotifier<List<EventModel>> events = ValueNotifier<List<EventModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  
  // ── Filter & Search State ────────────────────────────────────
  final ValueNotifier<String?> selectedJenisFilter = ValueNotifier(null);
  final ValueNotifier<DateTimeRange?> selectedDateRangeFilter = ValueNotifier(null);
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  
  bool _hasLoaded = false;
  List<EventModel> _allEvents = []; // Cache semua event dari Hive

  Future<void> loadEvents({bool force = false}) async {
    if (_hasLoaded && !force) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final box = HiveService.events;
      _allEvents = box.values.toList();
      _allEvents.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      
      // Apply filter pada load pertama
      _applyFilters();
      _hasLoaded = true;
    } catch (e) {
      errorMessage.value = 'Gagal memuat event: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Apply semua filter yang aktif dan update events.value
  void _applyFilters() {
    var filtered = List<EventModel>.from(_allEvents);

    // Filter by jenis
    if (selectedJenisFilter.value != null) {
      filtered = filtered.where((e) => e.jenis == selectedJenisFilter.value).toList();
    }

    // Filter by date range
    if (selectedDateRangeFilter.value != null) {
      final range = selectedDateRangeFilter.value!;
      filtered = filtered.where((e) {
        final eventDate = DateTime(e.tanggal.year, e.tanggal.month, e.tanggal.day);
        final startDate = DateTime(range.start.year, range.start.month, range.start.day);
        final endDate = DateTime(range.end.year, range.end.month, range.end.day);
        return !eventDate.isBefore(startDate) && !eventDate.isAfter(endDate);
      }).toList();
    }

    // Filter by search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((e) {
        return e.nama.toLowerCase().contains(query) ||
               e.jenis.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by tanggal
    filtered.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    events.value = filtered;
  }

  /// Set filter jenis event
  void setJenisFilter(String? jenis) {
    selectedJenisFilter.value = jenis;
    _applyFilters();
  }

  /// Set filter range tanggal
  void setDateRangeFilter(DateTimeRange? range) {
    selectedDateRangeFilter.value = range;
    _applyFilters();
  }

  /// Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  /// Reset semua filter
  void clearAllFilters() {
    selectedJenisFilter.value = null;
    selectedDateRangeFilter.value = null;
    searchQuery.value = '';
    _applyFilters();
  }

  /// Check apakah ada filter aktif
  bool get hasActiveFilters {
    return selectedJenisFilter.value != null ||
           selectedDateRangeFilter.value != null ||
           searchQuery.value.isNotEmpty;
  }

  Future<bool> createEvent({
    required String nama,
    required DateTime tanggal,
    String? parentEventId,
    String createdBy = 'unknown',
    String jenis = 'Kegiatan',
    String? deskripsi,
    List<String>? targetPeserta,
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
      final parentExists = _allEvents.any((e) => e.eventId == parentEventId);
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

      await HiveService.events.put(created.eventId, created);

      // Update cache dan filtered list
      _allEvents.add(created);
      _applyFilters();
      
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
      final index = _allEvents.indexWhere((e) => e.eventId == event.eventId);
      if (index < 0) {
        errorMessage.value = 'Event tidak ditemukan.';
        return false;
      }

      final saved = event.copyWith(nama: trimmed, isSynced: false);
      await HiveService.events.put(saved.eventId, saved);

      // Update cache dan filtered list
      _allEvents[index] = saved;
      _applyFilters();
      
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
      final toDelete = _allEvents
          .where((e) => e.eventId == eventId || e.parentEventId == eventId)
          .map((e) => e.eventId)
          .toList();

      for (final id in toDelete) {
        await HiveService.events.delete(id);
      }

      // Update cache dan filtered list
      _allEvents.removeWhere((e) => e.eventId == eventId || e.parentEventId == eventId);
      _applyFilters();
      
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

  List<EventModel> getSubEvents(String parentId) {
    return events.value.where((e) => e.parentEventId == parentId).toList()
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(date.year, date.month, date.day);
    return inputDay.isBefore(today);
  }

  void dispose() {
    events.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    selectedJenisFilter.dispose();
    selectedDateRangeFilter.dispose();
    searchQuery.dispose();
  }
}