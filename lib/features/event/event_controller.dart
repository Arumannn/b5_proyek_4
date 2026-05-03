import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../models/event_model.dart';
import '../auth/auth_controller.dart';
import 'event_permission.dart';

/// Controller untuk CRUD Event — Offline-First dengan cross-device sync.
///
/// ALUR DATA:
/// 1. createEvent/updateEvent/deleteEvent → simpan ke Hive dulu (offline-first)
/// 2. Jika online → langsung upsert ke MongoDB di background (fire-and-forget)
/// 3. Jika offline → isSynced=false, SyncManager akan handle saat online
///
/// CROSS-DEVICE SYNC:
/// - loadEvents() selalu pull dari MongoDB di background setelah load Hive
/// - Data dari MongoDB di-merge ke Hive (upsert berdasarkan eventId)
/// - Hasilnya: semua device selalu mendapat data terbaru
class EventController {
  static final EventController instance = EventController._internal();
  EventController._internal();

  final ValueNotifier<List<EventModel>> events =
      ValueNotifier<List<EventModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  // ── Filter & Search State ──────────────────────────────────────
  final ValueNotifier<String?> selectedJenisFilter = ValueNotifier(null);
  final ValueNotifier<DateTimeRange?> selectedDateRangeFilter = ValueNotifier(
    null,
  );
  final ValueNotifier<String> searchQuery = ValueNotifier('');

  bool _hasLoaded = false;
  List<EventModel> _allEvents = [];

  // RBAC: Ambil role user login saat ini untuk evaluasi izin di layer logic.
  String get _currentRole =>
      AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;

  // RBAC: createdBy wajib otomatis dari user login agar jejak audit konsisten.
  String? get _currentNim {
    final raw = AuthController.instance.currentUser.value?.nim;
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  // ══════════════════════════════════════════════════════════════
  // LOAD EVENTS — Hive + MongoDB merge
  // ══════════════════════════════════════════════════════════════

  /// Load event dari Hive (instan) lalu sync dari MongoDB di background.
  ///
  /// [force] — paksa reload meski sudah pernah load sebelumnya.
  /// [cloudSync] — jika true, akan pull dari MongoDB setelah load Hive.
  Future<void> loadEvents({bool force = false, bool cloudSync = true}) async {
    if (_hasLoaded && !force) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Step 1: Load dari Hive dulu (instan, offline-first)
      _allEvents = HiveService.events.values.toList();
      _allEvents.sort((a, b) => a.tanggal.compareTo(b.tanggal));
      _applyFilters();
      _hasLoaded = true;

      debugPrint('[EventCtrl] load Hive: ${_allEvents.length} event dimuat.');
    } catch (e) {
      errorMessage.value = 'Gagal memuat event: $e';
      debugPrint('[EventCtrl] load Hive error: $e');
    } finally {
      isLoading.value = false;
    }

    // Step 2: Pull dari MongoDB di background untuk cross-device sync
    if (cloudSync) {
      _pullFromCloudInBackground();
    }
  }

  /// Pull semua event dari MongoDB dan merge ke Hive + state.
  ///
  /// Dipanggil fire-and-forget setelah load Hive selesai,
  /// sehingga UI tidak menunggu koneksi cloud.
  Future<void> _pullFromCloudInBackground() async {
    try {
      if (!await _isOnline()) {
        debugPrint('[EventCtrl] pull cloud: offline, skip.');
        return;
      }

      if (!MongoService.instance.isConnected) {
        final connected = await MongoService.instance.ensureConnected();
        if (!connected) {
          debugPrint('[EventCtrl] pull cloud: MongoDB tidak terhubung.');
          return;
        }
      }

      debugPrint('[EventCtrl] pull cloud: mengambil semua event...');

      final cloudDocs = await MongoService.instance.findMany(
        collectionName: AppConstants.eventsCollection,
      );

      if (cloudDocs.isEmpty) {
        debugPrint('[EventCtrl] pull cloud: tidak ada event di cloud.');
        return;
      }

      debugPrint(
        '[EventCtrl] pull cloud: ${cloudDocs.length} event ditemukan.',
      );

      var newCount = 0;
      var updatedCount = 0;

      for (final doc in cloudDocs) {
        // Konversi ObjectId mongoDB jika ada
        final cleanDoc = _sanitizeMongoDoc(doc);
        final eventId = cleanDoc['eventId']?.toString();
        if (eventId == null || eventId.isEmpty) continue;

        final existingLocal = HiveService.events.get(eventId);

        if (existingLocal == null) {
          // Event baru dari cloud — simpan ke Hive
          final cloudEvent = EventModel.fromMap(cleanDoc);
          final synced = cloudEvent.copyWith(isSynced: true);
          await HiveService.events.put(synced.eventId, synced);
          newCount++;
        } else if (!existingLocal.isSynced) {
          // Event lokal yang belum sync → skip (jangan overwrite)
          // Nanti SyncManager yang akan push ke cloud
          continue;
        } else {
          // Event sudah synced — lokal tidak ada perubahan pending.
          // Timpa saja dengan data dari cloud agar selalu up-to-date
          // (karena Executive lain mungkin telah mengubah event ini).
          final cloudEvent = EventModel.fromMap(cleanDoc);
          final synced = cloudEvent.copyWith(isSynced: true);
          await HiveService.events.put(synced.eventId, synced);
          updatedCount++;
        }
      }

      if (newCount > 0 || updatedCount > 0) {
        // Reload dari Hive setelah merge untuk refresh UI
        _allEvents = HiveService.events.values.toList();
        _allEvents.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        _applyFilters();

        debugPrint(
          '[EventCtrl] pull cloud selesai: '
          '$newCount baru, $updatedCount diperbarui.',
        );
      } else {
        debugPrint('[EventCtrl] pull cloud: data sudah up-to-date.');
      }
    } catch (e, st) {
      // Error cloud tidak boleh crash app — cukup log
      debugPrint('[EventCtrl] pull cloud error: $e');
      debugPrint(st.toString());
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CREATE EVENT
  // ══════════════════════════════════════════════════════════════

  Future<bool> createEvent({
    required String nama,
    required DateTime tanggal,
    String? parentEventId,
    String createdBy = 'unknown',
    String jenis = 'Kegiatan',
    String? deskripsi,
    List<String>? targetPeserta,
  }) async {
    // RBAC: Tentukan scope izin berdasarkan apakah data adalah sub-event atau main event.
    final isSubEvent = parentEventId != null && parentEventId.isNotEmpty;
    // RBAC: Tolak CREATE jika role tidak punya izin pada scope event terkait.
    if (isSubEvent && !EventPermission.canCreateSubEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin membuat sub-event.';
      return false;
    }
    // RBAC: Main event hanya boleh dibuat oleh Executive.
    if (!isSubEvent && !EventPermission.canCreateMainEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin membuat main event.';
      return false;
    }

    // RBAC: createdBy harus otomatis berasal dari memberId user login.
    final actorNim = _currentNim;
    if (actorNim == null) {
      errorMessage.value = 'User login tidak valid untuk membuat event.';
      return false;
    }

    // ── Validasi ──────────────────────────────────────────────────
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
        createdBy: actorNim,
        parentEventId: parentEventId,
        deskripsi: deskripsi,
        targetPeserta: targetPeserta,
        isSynced: false, // akan di-update setelah cloud sync berhasil
      );

      // Step 1: Simpan ke Hive (offline-first)
      await HiveService.events.put(created.eventId, created);
      _allEvents.add(created);
      _applyFilters();

      debugPrint('[EventCtrl] create: saved to Hive — id=${created.eventId}');

      // Step 2: Sync ke MongoDB di background
      unawaited(_upsertEventToCloudInBackground(created));

      return true;
    } catch (e, st) {
      errorMessage.value = 'Gagal menambah event: $e';
      debugPrint('[EventCtrl] createEvent error: $e\n$st');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE EVENT
  // ══════════════════════════════════════════════════════════════

  Future<bool> updateEvent(EventModel event) async {
    // RBAC: Main event dan sub-event memiliki aturan UPDATE yang berbeda.
    final isSubEvent = event.parentEventId != null && event.parentEventId!.isNotEmpty;
    // RBAC: Tolak UPDATE sub-event untuk role tanpa hak tulis sub-event.
    if (isSubEvent && !EventPermission.canUpdateSubEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin mengubah sub-event.';
      return false;
    }
    // RBAC: Tolak UPDATE main event untuk role non-executive.
    if (!isSubEvent && !EventPermission.canUpdateMainEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin mengubah main event.';
      return false;
    }

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
      _allEvents[index] = saved;
      _applyFilters();

      debugPrint('[EventCtrl] update: saved to Hive — id=${saved.eventId}');

      // Sync ke MongoDB di background
      unawaited(_upsertEventToCloudInBackground(saved));

      return true;
    } catch (e, st) {
      errorMessage.value = 'Gagal mengubah event: $e';
      debugPrint('[EventCtrl] updateEvent error: $e\n$st');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // DELETE EVENT
  // ══════════════════════════════════════════════════════════════

  Future<bool> deleteEvent(String eventId) async {
    // RBAC: Validasi target delete agar izin dinilai dari tipe event aktual.
    final target = _allEvents.cast<EventModel?>().firstWhere(
      (e) => e?.eventId == eventId,
      orElse: () => null,
    );
    if (target == null) {
      errorMessage.value = 'Event tidak ditemukan.';
      return false;
    }

    // RBAC: Main event dan sub-event memiliki aturan DELETE yang berbeda.
    final isSubEvent = target.parentEventId != null && target.parentEventId!.isNotEmpty;
    // RBAC: Tolak DELETE sub-event jika role tidak memiliki izin.
    if (isSubEvent && !EventPermission.canDeleteSubEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin menghapus sub-event.';
      return false;
    }
    // RBAC: Tolak DELETE main event jika role bukan executive.
    if (!isSubEvent && !EventPermission.canDeleteMainEvent(_currentRole)) {
      errorMessage.value = 'Anda tidak memiliki izin menghapus main event.';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      // Kumpulkan semua ID yang perlu dihapus (termasuk sub-event)
      final toDelete = _allEvents
          .where((e) => e.eventId == eventId || e.parentEventId == eventId)
          .map((e) => e.eventId)
          .toList();

      // Hapus dari Hive
      for (final id in toDelete) {
        await HiveService.events.delete(id);
      }

      // Update cache & UI
      _allEvents.removeWhere(
        (e) => e.eventId == eventId || e.parentEventId == eventId,
      );
      _applyFilters();

      debugPrint(
        '[EventCtrl] delete: ${toDelete.length} event dihapus dari Hive.',
      );

      // Hapus dari MongoDB di background
      for (final id in toDelete) {
        unawaited(_deleteEventFromCloudInBackground(id));
      }

      return true;
    } catch (e, st) {
      errorMessage.value = 'Gagal menghapus event: $e';
      debugPrint('[EventCtrl] deleteEvent error: $e\n$st');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CLOUD SYNC HELPERS (fire-and-forget)
  // ══════════════════════════════════════════════════════════════

  /// Upsert satu event ke MongoDB.
  /// Jika online → langsung kirim.
  /// Jika offline → biarkan isSynced=false, SyncManager handle nanti.
  Future<void> _upsertEventToCloudInBackground(EventModel event) async {
    try {
      if (!await _isOnline()) {
        debugPrint(
          '[EventCtrl] cloud upsert: offline, ${event.eventId} tetap pending.',
        );
        return;
      }

      if (!MongoService.instance.isConnected) {
        final connected = await MongoService.instance.ensureConnected();
        if (!connected) {
          debugPrint(
            '[EventCtrl] cloud upsert: MongoDB tidak terhubung, skip.',
          );
          return;
        }
      }

      final payload = event.toMap()
        ..remove('isSynced'); // jangan simpan flag lokal ke cloud

      // Cek apakah dokumen sudah ada
      final existing = await MongoService.instance.findOne(
        collectionName: AppConstants.eventsCollection,
        filter: {'eventId': event.eventId},
      );

      if (existing == null) {
        // Insert baru
        await MongoService.instance.insertOne(
          collectionName: AppConstants.eventsCollection,
          document: payload,
        );
        debugPrint(
          '[EventCtrl] cloud upsert: ✅ INSERT ${event.eventId} ke MongoDB',
        );
      } else {
        // Update yang sudah ada
        await MongoService.instance.updateOne(
          collectionName: AppConstants.eventsCollection,
          filter: {'eventId': event.eventId},
          updateFields: payload,
        );
        debugPrint(
          '[EventCtrl] cloud upsert: ✅ UPDATE ${event.eventId} di MongoDB',
        );
      }

      // Tandai synced di Hive
      final updatedEvent = event.copyWith(isSynced: true);
      await HiveService.events.put(updatedEvent.eventId, updatedEvent);

      // Update cache internal juga
      final idx = _allEvents.indexWhere((e) => e.eventId == event.eventId);
      if (idx >= 0) {
        _allEvents[idx] = updatedEvent;
      }
    } catch (e) {
      if (MongoService.isDuplicateKeyError(e)) {
        // Duplicate key — data sudah ada di cloud, tandai synced
        debugPrint(
          '[EventCtrl] cloud upsert: duplicate ${event.eventId} — ditandai synced.',
        );
        final updatedEvent = event.copyWith(isSynced: true);
        await HiveService.events.put(updatedEvent.eventId, updatedEvent);
      } else {
        // Error lain — biarkan isSynced=false, SyncManager retry nanti
        debugPrint('[EventCtrl] cloud upsert error: $e');
      }
    }
  }

  /// Hapus event dari MongoDB.
  Future<void> _deleteEventFromCloudInBackground(String eventId) async {
    try {
      if (!await _isOnline()) {
        debugPrint('[EventCtrl] cloud delete: offline, skip $eventId.');
        return;
      }

      if (!MongoService.instance.isConnected) {
        await MongoService.instance.ensureConnected();
      }

      final removed = await MongoService.instance.deleteOne(
        collectionName: AppConstants.eventsCollection,
        filter: {'eventId': eventId},
      );

      debugPrint(
        '[EventCtrl] cloud delete: '
        '${removed > 0 ? "✅" : "⚠️ tidak ditemukan"} $eventId',
      );
    } catch (e) {
      debugPrint('[EventCtrl] cloud delete error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  // FILTER & SEARCH
  // ══════════════════════════════════════════════════════════════

  void _applyFilters() {
    var filtered = List<EventModel>.from(_allEvents);

    if (selectedJenisFilter.value != null) {
      filtered = filtered
          .where((e) => e.jenis == selectedJenisFilter.value)
          .toList();
    }

    if (selectedDateRangeFilter.value != null) {
      final range = selectedDateRangeFilter.value!;
      filtered = filtered.where((e) {
        final eventDate = DateTime(
          e.tanggal.year,
          e.tanggal.month,
          e.tanggal.day,
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

    filtered.sort((a, b) => a.tanggal.compareTo(b.tanggal));
    events.value = filtered;
  }

  void setJenisFilter(String? jenis) {
    selectedJenisFilter.value = jenis;
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
    selectedDateRangeFilter.value = null;
    searchQuery.value = '';
    _applyFilters();
  }

  bool get hasActiveFilters =>
      selectedJenisFilter.value != null ||
      selectedDateRangeFilter.value != null ||
      searchQuery.value.isNotEmpty;

  // ══════════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════════

  List<EventModel> getRootEvents() =>
      events.value.where((e) => e.parentEventId == null).toList();

  List<EventModel> getSubEvents(String parentId) =>
      events.value.where((e) => e.parentEventId == parentId).toList()
        ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(date.year, date.month, date.day);
    return inputDay.isBefore(today);
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.any((r) => r != ConnectivityResult.none);
  }

  /// Bersihkan dokumen MongoDB dari field internal (_id, dll)
  /// agar bisa diparse oleh EventModel.fromMap().
  Map<String, dynamic> _sanitizeMongoDoc(Map<String, dynamic> doc) {
    final clean = Map<String, dynamic>.from(doc);
    clean.remove('_id'); // ObjectId tidak bisa diparse Dart langsung
    return clean;
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
