import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'data/event_local_data_source.dart';
import 'data/event_remote_data_source.dart';
import '../../../models/event_model.dart';
import '../../../models/event_invitation.dart';
import '../../../core/controllers/config_controller.dart';
import 'event_permission.dart';

class EventRepository {
  final EventLocalDataSource _local;
  final EventRemoteDataSource _remote;

  EventRepository(this._local, this._remote);

  List<EventModel> getAllEvents() {
    return _local.getAllEvents();
  }

  Future<void> pullFromCloud() async {
    try {
      if (!await _isOnline()) return;

      final cloudDocs = await _remote.fetchEventsFromCloud();
      if (cloudDocs.isEmpty) return;

      for (final cleanDoc in cloudDocs) {
        final eventId = cleanDoc['eventId']?.toString();
        if (eventId == null || eventId.isEmpty) continue;

        final cloudEvent = EventModel.fromMap(cleanDoc);
        final existingLocal = _local.getEventById(eventId);

        if (existingLocal == null) {
          final synced = cloudEvent.copyWith(isSynced: true);
          await _local.saveEvent(synced);
        } else if (!existingLocal.isSynced) {
          // Event lokal belum sync — skip, biarkan SyncManager yang push
          continue;
        } else {
          final synced = cloudEvent.copyWith(isSynced: true);
          await _local.saveEvent(synced);
        }
      }
    } catch (e, st) {
      debugPrint('[EventRepo] pull cloud error: $e\n$st');
    }
  }

  Future<EventModel> createEvent({
    required String currentRole,
    required String loginNim,
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
    final trimmed = nama.trim();
    if (trimmed.isEmpty) throw Exception('Nama event wajib diisi.');
    if (!ConfigController.instance.eventTypes.contains(jenis)) {
      throw Exception('Jenis event tidak valid.');
    }
    if (_isPastDay(tanggalMulai)) {
      throw Exception('Tanggal event tidak boleh masa lalu.');
    }

    final isSubEvent = parentEventId != null && parentEventId.isNotEmpty;
    if (isSubEvent) {
      final parentEvent = _local.getEventById(parentEventId!);
      if (parentEvent == null) throw Exception('Parent event tidak ditemukan.');
      if (!EventPermission.canCreateSubEvent(currentRole)) {
        throw Exception('Anda tidak memiliki izin membuat sub-event.');
      }
    } else {
      if (!EventPermission.canCreateMainEvent(currentRole)) {
        throw Exception('Anda tidak memiliki izin membuat main event.');
      }
    }

    final explicitCreatedBy = createdBy.trim();
    final actorNim = explicitCreatedBy.isNotEmpty
        ? explicitCreatedBy
        : (loginNim.isNotEmpty ? loginNim : null);

    if (actorNim == null) {
      throw Exception('User login tidak valid untuk membuat event.');
    }

    final created = EventModel(
      eventId: DateTime.now().microsecondsSinceEpoch.toString(),
      nama: trimmed,
      jenis: jenis,
      tanggalMulai: tanggalMulai,
      tanggalSelesai: tanggalSelesai,
      jamSelesai: jamSelesai,
      createdBy: actorNim,
      parentEventId: parentEventId,
      lokasi: lokasi,
      deskripsi: deskripsi,
      targetPeserta: targetPeserta,
      requiresInvitation: requiresInvitation,
      penyelenggara: penyelenggara,
      penanggungJawab: penanggungJawab,
      isSynced: false,
    );

    await _local.saveEvent(created);

    if (targetPeserta != null && targetPeserta.isNotEmpty) {
      final now = DateTime.now();
      for (final targetNim in targetPeserta) {
        final invitationId = 'INV-${created.eventId}-${now.microsecondsSinceEpoch}-$targetNim';
        final invitation = EventInvitation(
          invitationId: invitationId,
          eventId: created.eventId,
          nim: targetNim,
          attendanceTime: now,
          invitedBy: actorNim,
          invitedAt: now,
          isSynced: false,
        );
        await _local.saveInvitation(invitation);
      }
    }

    unawaited(upsertEventToCloudInBackground(created));
    return created;
  }

  Future<EventModel> updateEvent({
    required EventModel event,
    required String currentRole,
  }) async {
    final trimmed = event.nama.trim();
    if (trimmed.isEmpty) throw Exception('Nama event wajib diisi.');
    if (!ConfigController.instance.eventTypes.contains(event.jenis)) {
      throw Exception('Jenis event tidak valid.');
    }
    if (_isPastDay(event.tanggalMulai)) {
      throw Exception('Tanggal event tidak boleh masa lalu.');
    }

    final isSubEvent = event.parentEventId != null && event.parentEventId!.isNotEmpty;
    if (isSubEvent && !EventPermission.canUpdateSubEvent(currentRole)) {
      throw Exception('Anda tidak memiliki izin mengubah sub-event.');
    }
    if (!isSubEvent && !EventPermission.canUpdateMainEvent(currentRole)) {
      throw Exception('Anda tidak memiliki izin mengubah main event.');
    }

    final existing = _local.getEventById(event.eventId);
    if (existing == null) throw Exception('Event tidak ditemukan.');

    final saved = event.copyWith(
      nama: trimmed,
      isSynced: false,
      version: event.version + 1,
    );
    saved.refreshStatus();
    await _local.saveEvent(saved);

    if (saved.requiresInvitation && saved.targetPeserta.isNotEmpty) {
      final now = DateTime.now();
      for (final targetNim in saved.targetPeserta) {
        if (!_local.hasInvitation(saved.eventId, targetNim)) {
          final invitationId = 'INV-${saved.eventId}-${now.microsecondsSinceEpoch}-$targetNim';
          final invitation = EventInvitation(
            invitationId: invitationId,
            eventId: saved.eventId,
            nim: targetNim,
            attendanceTime: now,
            invitedBy: currentRole,
            invitedAt: now,
            isSynced: false,
          );
          await _local.saveInvitation(invitation);
        }
      }
    }

    unawaited(upsertEventToCloudInBackground(saved));
    return saved;
  }

  Future<List<EventModel>> deleteEvent({
    required String eventId,
    required String currentRole,
  }) async {
    final target = _local.getEventById(eventId);
    if (target == null) throw Exception('Event tidak ditemukan.');

    final isSubEvent = target.parentEventId != null && target.parentEventId!.isNotEmpty;
    if (isSubEvent && !EventPermission.canDeleteSubEvent(currentRole)) {
      throw Exception('Anda tidak memiliki izin menghapus sub-event.');
    }
    if (!isSubEvent && !EventPermission.canDeleteMainEvent(currentRole)) {
      throw Exception('Anda tidak memiliki izin menghapus main event.');
    }

    final allEvents = _local.getAllEvents();
    final toDelete = allEvents
        .where((e) => e.eventId == eventId || e.parentEventId == eventId)
        .toList();

    final now = DateTime.now();
    final deletedEvents = <EventModel>[];

    for (final event in toDelete) {
      final softDeleted = event.copyWith(deletedAt: now, isSynced: false);
      await _local.saveEvent(softDeleted);
      deletedEvents.add(softDeleted);
      unawaited(upsertEventToCloudInBackground(softDeleted));
    }

    return deletedEvents;
  }

  Future<void> upsertEventToCloudInBackground(EventModel event) async {
    try {
      if (!await _isOnline()) return;

      final payload = event.toMap()..remove('isSynced');
      final success = await _remote.upsertEventToCloud(payload);
      
      if (success) {
        final updatedEvent = event.copyWith(isSynced: true);
        await _local.saveEvent(updatedEvent);
      }
    } catch (e) {
      debugPrint('[EventRepo] cloud upsert error: $e');
    }
  }

  Future<bool> pushPendingUpdatesToCloudInBackground() async {
    if (!await _isOnline()) return false;
    
    final pending = _local.getPendingSyncedEvents();
    bool hasUpdates = false;
    for (final event in pending) {
      await upsertEventToCloudInBackground(event);
      hasUpdates = true;
    }
    return hasUpdates;
  }

  bool refreshAllStatuses(List<EventModel> events) {
    bool hasUpdates = false;
    for (final event in events) {
      if (event.deletedAt != null) continue;
      final oldStatus = event.statusEvent;
      event.refreshStatus();
      if (oldStatus != event.statusEvent) {
        try {
          event.save(); // HiveObject save
          event.isSynced = false;
          event.save();
          hasUpdates = true;
        } catch (e) {
          debugPrint('[EventRepo] gagal menyimpan status update: $e');
        }
      }
    }
    if (hasUpdates) {
      unawaited(pushPendingUpdatesToCloudInBackground());
    }
    return hasUpdates;
  }

  bool _isPastDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inputDay = DateTime(date.year, date.month, date.day);
    return inputDay.isBefore(today);
  }

  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }
}
