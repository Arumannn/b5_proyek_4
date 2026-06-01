import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../auth/auth_controller.dart';

import 'data/event_local_data_source.dart';
import 'data/event_remote_data_source.dart';
import 'repositories/event_repository.dart';

class EventController {
  static final EventController instance = EventController._internal();

  late final EventRepository _repository;
  
  EventController._internal() {
    _repository = EventRepository(
      EventLocalDataSource(),
      EventRemoteDataSource(),
    );
  }

  final ValueNotifier<List<EventModel>> events = ValueNotifier<List<EventModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  final ValueNotifier<String?> selectedJenisFilter = ValueNotifier(null);
  final ValueNotifier<String?> selectedPenyelenggaraFilter = ValueNotifier(null);
  final ValueNotifier<DateTimeRange?> selectedDateRangeFilter = ValueNotifier(null);
  final ValueNotifier<String> searchQuery = ValueNotifier('');

  bool _hasLoaded = false;
  Timer? _statusRefreshTimer;

  String get _currentRole =>
      AuthController.instance.currentUser.value?.role ?? AppConstants.roleExecutive;
      
  String get _loginNim =>
      AuthController.instance.currentUser.value?.nim ?? '';

  void _startStatusRefreshTimer() {
    if (_statusRefreshTimer?.isActive == true) return;

    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final allEvents = _repository.getAllEvents();
      if (allEvents.isEmpty) return;
      
      if (_repository.refreshAllStatuses(allEvents)) {
        _applyFilters();
      }
    });
  }

  Future<void> loadEvents({bool force = false, bool cloudSync = true}) async {
    if (_hasLoaded && !force) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final allEvents = _repository.getAllEvents();
      _repository.refreshAllStatuses(allEvents);
      
      _applyFilters();
      _hasLoaded = true;
      _startStatusRefreshTimer();
    } catch (e) {
      errorMessage.value = 'Gagal memuat event: $e';
    } finally {
      isLoading.value = false;
    }

    if (cloudSync) {
      unawaited(_pullFromCloud());
    }
  }

  Future<void> refreshEvents({bool cloudSync = true}) async {
    await loadEvents(force: true, cloudSync: false);

    if (cloudSync) {
      await _pullFromCloud();
    }
  }

  Future<void> _pullFromCloud() async {
    try {
      await _repository.pullFromCloud();
      _applyFilters();
    } catch (e) {
      debugPrint('[EventCtrl] pull cloud error: $e');
    }
  }

  Future<bool> createEvent({
    required String nama,
    required DateTime tanggalMulai,
    DateTime? tanggalSelesai,
    DateTime? jamSelesai,
    String? parentEventId,
    String createdBy = 'unknown',
    String jenis = 'Kegiatan',
    String? lokasi,
    String? deskripsi,
    List<String>? targetPeserta,
    bool requiresInvitation = false,
    String? penyelenggara,
    String? penanggungJawab,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.createEvent(
        currentRole: _currentRole,
        loginNim: _loginNim,
        nama: nama,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        jamSelesai: jamSelesai,
        parentEventId: parentEventId,
        createdBy: createdBy,
        jenis: jenis,
        lokasi: lokasi,
        deskripsi: deskripsi,
        targetPeserta: targetPeserta,
        requiresInvitation: requiresInvitation,
        penyelenggara: penyelenggara,
        penanggungJawab: penanggungJawab,
      );
      
      _applyFilters();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEvent(EventModel event) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.updateEvent(event: event, currentRole: _currentRole);
      _applyFilters();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.deleteEvent(eventId: eventId, currentRole: _currentRole);
      _applyFilters();
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    final allEvents = _repository.getAllEvents();
    var filtered = allEvents.where((e) => e.deletedAt == null).toList();

    if (selectedJenisFilter.value != null) {
      filtered = filtered
          .where((e) => e.jenis == selectedJenisFilter.value)
          .toList();
    }

    if (selectedPenyelenggaraFilter.value != null) {
      filtered = filtered
          .where((e) => e.penyelenggara == selectedPenyelenggaraFilter.value)
          .toList();
    }

    if (selectedDateRangeFilter.value != null) {
      final range = selectedDateRangeFilter.value!;
      filtered = filtered.where((e) {
        final eventDate = DateTime(
          e.tanggalMulai.year,
          e.tanggalMulai.month,
          e.tanggalMulai.day,
        );
        final startDate = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final endDate = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
        );
        return !eventDate.isBefore(startDate) && !eventDate.isAfter(endDate);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered
          .where(
            (e) =>
                e.nama.toLowerCase().contains(query) ||
                e.jenis.toLowerCase().contains(query),
          )
          .toList();
    }

    filtered.sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
    events.value = filtered;
  }

  void setJenisFilter(String? jenis) {
    selectedJenisFilter.value = jenis;
    _applyFilters();
  }

  void setPenyelenggaraFilter(String? penyelenggara) {
    selectedPenyelenggaraFilter.value = penyelenggara;
    _applyFilters();
  }

  void setDateRangeFilter(DateTimeRange? range) {
    selectedDateRangeFilter.value = range;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void clearAllFilters() {
    selectedJenisFilter.value = null;
    selectedPenyelenggaraFilter.value = null;
    selectedDateRangeFilter.value = null;
    searchQuery.value = '';
    _applyFilters();
  }

  bool get hasActiveFilters =>
      selectedJenisFilter.value != null ||
      selectedPenyelenggaraFilter.value != null ||
      selectedDateRangeFilter.value != null ||
      searchQuery.value.isNotEmpty;

  List<EventModel> getRootEvents() =>
      events.value.where((e) => e.parentEventId == null).toList();

  List<EventModel> getSubEvents(String parentId) =>
      events.value.where((e) => e.parentEventId == parentId).toList()
        ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

  void dispose() {
    events.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    selectedJenisFilter.dispose();
    selectedPenyelenggaraFilter.dispose();
    selectedDateRangeFilter.dispose();
    searchQuery.dispose();
  }
}
