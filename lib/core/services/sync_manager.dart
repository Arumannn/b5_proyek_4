import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../models/attendance_record.dart';
import '../../models/permission_record.dart';
import 'cloudinary_service.dart';
import 'hive_service.dart';
import 'mongo_service.dart';
import '../../models/event_model.dart';
import '../../models/event_invitation.dart';

/// SyncManager — Versi lengkap Week 11.
///
/// TANGGUNG JAWAB:
/// 1. Mendengarkan perubahan koneksi (Connectivity) secara real-time.
/// 2. Auto-trigger sync saat status berubah dari offline → online.
/// 3. Sync AttendanceRecord pending → MongoDB Atlas.
/// 4. Sync PermissionRecord pending:
///    a. Jika ada buktiFotoPath & buktiFotoUrl null → upload ke Cloudinary dulu.
///    b. Setelah upload sukses → kirim ke MongoDB.
/// 5. Retry logic: maks 3x dengan delay 5 detik untuk error selain duplikat.
///
/// ANTI-DUPLIKASI:
/// - MongoDB menjaga unique index pada `compositeKey` (attendance)
///   dan `permissionId` (permissions).
/// - Jika insert gagal karena duplicate key (11000) → tandai isSynced=true
///   tanpa melempar error (data sudah ada di cloud dari perangkat lain).
///
/// PENGGUNAAN:
///   // Di main() — cukup panggil sekali
///   SyncManager.instance.startListening();
///
///   // Trigger manual (opsional, misal tombol "Sync Sekarang")
///   await SyncManager.instance.syncAll();
class SyncManager {
  // ─── Singleton ──────────────────────────────────────────────────
  static final SyncManager instance = SyncManager._internal();
  SyncManager._internal();

  // ─── State ──────────────────────────────────────────────────────
  bool _isListening = false;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  List<EventModel> _allEventsCache = [];

  // ─── Reactive State (opsional untuk UI) ─────────────────────────
  /// Jumlah record yang masih menunggu sync — berguna untuk badge di UI.
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// true saat sedang proses sync — berguna untuk loading indicator.
  final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  // ─── START LISTENING ────────────────────────────────────────────

  /// Mulai memantau koneksi dan auto-trigger sync.
  /// Dipanggil SEKALI di main() setelah HiveService.init().
  void startListening() {
    if (_isListening) {
      debugPrint('[SyncManager] sudah listening, skip.');
      return;
    }

    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen(_onConnectivityChanged);

    _isListening = true;
    debugPrint('[SyncManager] ✅ listening aktif — auto-sync saat online.');

    // Update pending count awal
    _updatePendingCount();

    // Trigger sync awal jika sudah ada koneksi internet saat app dibuka
    Connectivity().checkConnectivity().then((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint('[SyncManager] 🌐 koneksi awal tersedia → trigger syncAll()');
        // Ensure MongoDB is connected before syncing
        MongoService.instance.ensureConnected().then((_) {
          syncAll();
        }).catchError((e) {
          debugPrint('[SyncManager] ❌ MongoDB tidak siap untuk sync awal: $e');
        });
      }
    });
  }

  /// Hentikan listener (panggil saat app dispose jika perlu).
  Future<void> stopListening() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _isListening = false;
    debugPrint('[SyncManager] stopped.');
  }

  // ─── CONNECTIVITY HANDLER ────────────────────────────────────────

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);

    if (isOnline) {
      debugPrint('[SyncManager] 🌐 koneksi tersedia → trigger syncAll()');
      // Ensure MongoDB is connected before syncing
      MongoService.instance.ensureConnected().then((_) {
        syncAll();
      }).catchError((e) {
        debugPrint('[SyncManager] ⚠️ MongoDB tidak siap untuk sync: $e');
      });
    } else {
      debugPrint('[SyncManager] 📴 offline — sync ditunda.');
    }
  }

  // ─── SYNC ALL ────────────────────────────────────────────────────

  /// Sync semua data pending: Push + Pull untuk Attendance, Permission, Events, Invitations.
  /// Aman dipanggil berkali-kali — ada guard _isSyncing.
  Future<void> syncAll() async {
    if (_isSyncing) {
      debugPrint('[SyncManager] sync sedang berjalan, request baru diabaikan.');
      return;
    }

    if (!MongoService.instance.isConnected) {
      final connected = await MongoService.instance.ensureConnected();
      if (!connected) {
        debugPrint('[SyncManager] gagal connect ke MongoDB, sync dibatalkan.');
        return;
      }
    }

    _isSyncing = true;
    isSyncing.value = true;

    try {
      // Push pending data ke MongoDB
      await syncPendingAttendance();
      await syncPendingPermissions();
      await syncPendingEvents();
      await syncPendingInvitations();

      // Pull data dari MongoDB ke Hive
      await pullAttendanceFromCloud();
      await pullPermissionsFromCloud();
      await pullInvitationsFromCloud();

      await _pullLatestFromCloud();
      _updatePendingCount();
    } finally {
      _isSyncing = false;
      isSyncing.value = false;
    }
  }

  /// Pull data event terbaru dari cloud ke Hive setelah sync selesai.
  /// Memastikan soft-delete dan perubahan dari perangkat lain masuk ke lokal.
  Future<void> _pullLatestFromCloud() async {
    try {
      if (!MongoService.instance.isConnected) return;

      final cloudDocs = await MongoService.instance.findMany(
        collectionName: AppConstants.eventsCollection,
      );

      if (cloudDocs.isEmpty) return;

      var pullCount = 0;
      for (final doc in cloudDocs) {
        final clean = Map<String, dynamic>.from(doc)..remove('_id');
        final eventId = clean['eventId']?.toString();
        if (eventId == null || eventId.isEmpty) continue;

        final cloudEvent = EventModel.fromMap(clean);
        final localEvent = HiveService.events.get(eventId);

        // Kalau lokal tidak ada, atau cloud lebih baru (versi lebih tinggi),
        // atau cloud punya deletedAt tapi lokal belum — update lokal
        final shouldUpdate = localEvent == null ||
            cloudEvent.version > localEvent.version ||
            (cloudEvent.deletedAt != null && localEvent.deletedAt == null);

        if (shouldUpdate) {
          final synced = cloudEvent.copyWith(isSynced: true);
          await HiveService.events.put(synced.eventId, synced);
          pullCount++;
        }
      }

      if (pullCount > 0) {
        debugPrint('[SyncManager] pull-after-push: $pullCount event diperbarui dari cloud.');
      }
    } catch (e) {
      // Pull gagal tidak boleh crash app — cukup log
      debugPrint('[SyncManager] pull-after-push error: $e');
    }
  }

  // ─── SYNC ATTENDANCE ─────────────────────────────────────────────

  /// Sync semua AttendanceRecord dengan isSynced=false ke MongoDB.
  Future<void> syncPendingAttendance() async {
    final pending = HiveService.attendance.values
        .where((r) => !r.isSynced)
        .toList(growable: false);

    if (pending.isEmpty) {
      debugPrint('[SyncManager] attendance: tidak ada pending.');
      return;
    }

    debugPrint('[SyncManager] attendance: ${pending.length} record pending.');

    var successCount = 0;
    var skipCount = 0;
    var failCount = 0;

    for (final record in pending) {
      final success = await _syncAttendanceWithRetry(record);
      if (success == _SyncResult.success) {
        successCount++;
      } else if (success == _SyncResult.duplicate) {
        skipCount++;
      } else {
        failCount++;
      }
    }

    debugPrint(
      '[SyncManager] attendance selesai: '
      '$successCount synced, $skipCount duplicate, $failCount gagal.',
    );
  }

  /// Sync satu AttendanceRecord dengan retry logic.
  Future<_SyncResult> _syncAttendanceWithRetry(AttendanceRecord record) async {
    for (var attempt = 1; attempt <= AppConstants.maxSyncRetries; attempt++) {
      try {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.attendanceCollection,
          document: record.toMap(),
        );

        record.isSynced = true;
        await record.save();

        debugPrint(
          '[SyncManager] attendance ✅ synced: ${record.recordId} '
          '(attempt $attempt)',
        );
        return _SyncResult.success;
      } catch (e) {
        if (MongoService.isDuplicateKeyError(e)) {
          record.isSynced = true;
          await record.save();
          debugPrint(
            '[SyncManager] attendance ⚠️ duplicate: ${record.recordId} '
            '— ditandai synced.',
          );
          return _SyncResult.duplicate;
        }

        debugPrint(
          '[SyncManager] attendance ❌ attempt $attempt '
          'gagal untuk ${record.recordId}: $e',
        );

        if (attempt < AppConstants.maxSyncRetries) {
          debugPrint(
            '[SyncManager] retry dalam '
            '${AppConstants.syncRetryDelay.inSeconds}s...',
          );
          await Future.delayed(AppConstants.syncRetryDelay);
        }
      }
    }

    debugPrint(
      '[SyncManager] attendance 🔴 maks retry tercapai untuk '
      '${record.recordId} — tetap pending.',
    );
    return _SyncResult.failed;
  }

  // ─── SYNC PERMISSION ─────────────────────────────────────────────

  /// Sync semua PermissionRecord dengan isSynced=false ke MongoDB.
  /// Jika ada buktiFotoPath dan buktiFotoUrl null → upload ke Cloudinary dulu.
  Future<void> syncPendingPermissions() async {
    final pending = HiveService.permissions.values
        .where((p) => !p.isSynced)
        .toList(growable: false);

    if (pending.isEmpty) {
      debugPrint('[SyncManager] permission: tidak ada pending.');
      return;
    }

    debugPrint('[SyncManager] permission: ${pending.length} record pending.');

    var successCount = 0;
    var skipCount = 0;
    var failCount = 0;

    for (final permission in pending) {
      final result = await _syncPermissionWithRetry(permission);
      if (result == _SyncResult.success) {
        successCount++;
      } else if (result == _SyncResult.duplicate) {
        skipCount++;
      } else {
        failCount++;
      }
    }

    debugPrint(
      '[SyncManager] permission selesai: '
      '$successCount synced, $skipCount duplicate, $failCount gagal.',
    );
  }

  /// Sync satu PermissionRecord dengan retry logic.
  Future<_SyncResult> _syncPermissionWithRetry(
      PermissionRecord permission) async {
    for (var attempt = 1; attempt <= AppConstants.maxSyncRetries; attempt++) {
      try {
        // ── Step 1: Upload foto bukti ke Cloudinary (jika belum) ────
        if (permission.buktiFotoPath != null &&
            permission.buktiFotoPath!.isNotEmpty &&
            (permission.buktiFotoUrl == null ||
                permission.buktiFotoUrl!.isEmpty)) {
          debugPrint(
            '[SyncManager] permission: upload foto untuk '
            '${permission.permissionId}...',
          );

          final uploadedUrl = await CloudinaryService.instance.uploadFile(
            localPath: permission.buktiFotoPath!,
            folder: 'prasasti/izin',
            publicId: 'izin_${permission.permissionId}',
          );

          if (uploadedUrl == null) {
            debugPrint(
              '[SyncManager] permission ⚠️ upload foto gagal untuk '
              '${permission.permissionId} — tetap pending.',
            );

            if (attempt < AppConstants.maxSyncRetries) {
              await Future.delayed(AppConstants.syncRetryDelay);
              continue;
            }
            return _SyncResult.failed;
          }

          permission.buktiFotoUrl = uploadedUrl;
          await permission.save();

          debugPrint(
            '[SyncManager] permission ✅ foto uploaded: $uploadedUrl',
          );
        }

        // ── Step 2: Insert ke MongoDB ────────────────────────────────
        await MongoService.instance.insertOne(
          collectionName: AppConstants.permissionsCollection,
          document: permission.toMap(),
        );

        permission.isSynced = true;
        await permission.save();

        debugPrint(
          '[SyncManager] permission ✅ synced: ${permission.permissionId} '
          '(attempt $attempt)',
        );
        return _SyncResult.success;
      } catch (e) {
        if (MongoService.isDuplicateKeyError(e)) {
          permission.isSynced = true;
          await permission.save();
          debugPrint(
            '[SyncManager] permission ⚠️ duplicate: ${permission.permissionId}'
            ' — ditandai synced.',
          );
          return _SyncResult.duplicate;
        }

        debugPrint(
          '[SyncManager] permission ❌ attempt $attempt '
          'gagal untuk ${permission.permissionId}: $e',
        );

        if (attempt < AppConstants.maxSyncRetries) {
          debugPrint(
            '[SyncManager] retry dalam '
            '${AppConstants.syncRetryDelay.inSeconds}s...',
          );
          await Future.delayed(AppConstants.syncRetryDelay);
        }
      }
    }

    debugPrint(
      '[SyncManager] permission 🔴 maks retry tercapai untuk '
      '${permission.permissionId} — tetap pending.',
    );
    return _SyncResult.failed;
  }

  // ─── SYNC EVENTS ─────────────────────────────────────────────────

  /// Sync semua EventModel dengan isSynced=false ke MongoDB.
  Future<void> syncPendingEvents() async {
    final pending = HiveService.events.values
        .where((e) => !e.isSynced)
        .toList(growable: false);

    if (pending.isEmpty) {
      debugPrint('[SyncManager] events: tidak ada pending.');
      return;
    }

    debugPrint('[SyncManager] events: ${pending.length} event pending.');

    var successCount = 0;
    var skipCount = 0;
    var failCount = 0;

    for (final event in pending) {
      final result = await _syncEventWithRetry(event);
      if (result == _SyncResult.success) {
        successCount++;
      } else if (result == _SyncResult.duplicate) {
        skipCount++;
      } else {
        failCount++;
      }
    }

    debugPrint(
      '[SyncManager] events selesai: '
      '$successCount synced, $skipCount duplicate, $failCount gagal.',
    );
  }

  /// Sync satu EventModel ke MongoDB dengan retry logic.
  Future<_SyncResult> _syncEventWithRetry(EventModel event) async {
    for (var attempt = 1; attempt <= AppConstants.maxSyncRetries; attempt++) {
      try {
        final payload = event.toMap()..remove('isSynced');

        final existing = await MongoService.instance.findOne(
          collectionName: AppConstants.eventsCollection,
          filter: {'eventId': event.eventId},
        );

        if (existing == null) {
          // Dokumen belum ada di cloud — insert baru
          await MongoService.instance.insertOne(
            collectionName: AppConstants.eventsCollection,
            document: payload,
          );
        } else {
          // Dokumen sudah ada — update dengan cek versi
          final cloudVersion = (existing['version'] as int?) ?? 1;
          final localVersion = event.version;

          if (localVersion < cloudVersion) {
            // Cloud lebih baru — data lokal ketinggalan, jangan overwrite
            debugPrint(
              '[SyncManager] event KONFLIK VERSI: ${event.eventId} '
              '— lokal v$localVersion < cloud v$cloudVersion. '
              'Skip push, akan diperbarui saat pull berikutnya.',
            );
            // Tandai isSynced=true agar tidak loop, tapi data lokal
            // akan diperbarui saat loadEvents() berikutnya
            final updated = event.copyWith(isSynced: true);
            await HiveService.events.put(updated.eventId, updated);
            return _SyncResult.duplicate;
          }

          final nModified = await MongoService.instance.updateOne(
            collectionName: AppConstants.eventsCollection,
            filter: {'eventId': event.eventId},
            updateFields: payload,
          );

          if (nModified == 0) {
            // Update tidak mengubah apapun — kemungkinan konflik tersembunyi
            debugPrint(
              '[SyncManager] WARNING event ${event.eventId}: '
              'updateOne nModified=0. Mungkin konflik versi atau event '
              'sudah dihapus perangkat lain.',
            );
            final updated = event.copyWith(isSynced: true);
            await HiveService.events.put(updated.eventId, updated);
            return _SyncResult.duplicate;
          }
        }

        // Sukses — tandai isSynced di Hive
        final updated = event.copyWith(isSynced: true);
        await HiveService.events.put(updated.eventId, updated);

        final idx = _allEventsCache.indexOf(event);
        if (idx >= 0) _allEventsCache[idx] = updated;

        debugPrint(
          '[SyncManager] event synced: ${event.eventId} '
          'v${event.version} (attempt $attempt)',
        );
        return _SyncResult.success;
      } catch (e) {
        if (MongoService.isDuplicateKeyError(e)) {
          final updated = event.copyWith(isSynced: true);
          await HiveService.events.put(updated.eventId, updated);
          debugPrint('[SyncManager] event duplicate: ${event.eventId} — ditandai synced.');
          return _SyncResult.duplicate;
        }

        debugPrint('[SyncManager] event attempt $attempt gagal ${event.eventId}: $e');
        if (attempt < AppConstants.maxSyncRetries) {
          await Future.delayed(AppConstants.syncRetryDelay);
        }
      }
    }

    debugPrint('[SyncManager] event maks retry: ${event.eventId} — tetap pending.');
    return _SyncResult.failed;
  }

  // ─── SYNC INVITATIONS ──────────────────────────────────────────────

  /// Sync semua EventInvitation dengan isSynced=false ke MongoDB.
  Future<void> syncPendingInvitations() async {
    final pending = HiveService.invitations.values
        .where((i) => !i.isSynced)
        .toList(growable: false);

    if (pending.isEmpty) {
      debugPrint('[SyncManager] invitations: tidak ada pending.');
      return;
    }

    debugPrint('[SyncManager] invitations: ${pending.length} record pending.');

    var successCount = 0;
    var skipCount = 0;
    var failCount = 0;

    for (final invitation in pending) {
      final result = await _syncInvitationWithRetry(invitation);
      if (result == _SyncResult.success) {
        successCount++;
      } else if (result == _SyncResult.duplicate) {
        skipCount++;
      } else {
        failCount++;
      }
    }

    debugPrint(
      '[SyncManager] invitations selesai: '
      '$successCount synced, $skipCount duplicate, $failCount gagal.',
    );
  }

  /// Sync satu EventInvitation ke MongoDB dengan retry logic.
  Future<_SyncResult> _syncInvitationWithRetry(
      EventInvitation invitation) async {
    for (var attempt = 1; attempt <= AppConstants.maxSyncRetries; attempt++) {
      try {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.invitationsCollection,
          document: invitation.toJson(),
        );

        invitation.isSynced = true;
        await HiveService.invitations.put(
            invitation.invitationId, invitation);

        debugPrint(
          '[SyncManager] invitation ✅ synced: ${invitation.invitationId} '
          '(attempt $attempt)',
        );
        return _SyncResult.success;
      } catch (e) {
        if (MongoService.isDuplicateKeyError(e)) {
          invitation.isSynced = true;
          await HiveService.invitations.put(
              invitation.invitationId, invitation);
          debugPrint(
            '[SyncManager] invitation ⚠️ duplicate: '
            '${invitation.invitationId} — ditandai synced.',
          );
          return _SyncResult.duplicate;
        }

        debugPrint(
          '[SyncManager] invitation ❌ attempt $attempt '
          'gagal untuk ${invitation.invitationId}: $e',
        );

        if (attempt < AppConstants.maxSyncRetries) {
          debugPrint(
            '[SyncManager] retry dalam '
            '${AppConstants.syncRetryDelay.inSeconds}s...',
          );
          await Future.delayed(AppConstants.syncRetryDelay);
        }
      }
    }

    debugPrint(
      '[SyncManager] invitation 🔴 maks retry tercapai untuk '
      '${invitation.invitationId} — tetap pending.',
    );
    return _SyncResult.failed;
  }

  // ─── PULL ATTENDANCE FROM CLOUD ──────────────────────────────────

  /// Pull semua AttendanceRecord dari MongoDB dan merge ke Hive lokal.
  /// Menggunakan compositeKey (eventId + nim) sebagai identifier unik.
  Future<void> pullAttendanceFromCloud() async {
    try {
      final cloudDocs = await MongoService.instance.findMany(
        collectionName: AppConstants.attendanceCollection,
      );

      if (cloudDocs.isEmpty) {
        debugPrint('[SyncManager] pullAttendance: tidak ada data di cloud.');
        return;
      }

      var insertCount = 0;
      var updateCount = 0;

      for (final doc in cloudDocs) {
        final record = AttendanceRecord.fromMap(doc);
        final existingKey = HiveService.attendance.keys.cast<dynamic>().firstWhere(
          (key) {
            final existing = HiveService.attendance.get(key);
            return existing?.compositeKey == record.compositeKey;
          },
          orElse: () => null,
        );

        if (existingKey != null) {
          final existing = HiveService.attendance.get(existingKey)!;
          // Update hanya jika data cloud lebih baru
          if (record.timestamp.isAfter(existing.timestamp)) {
            await HiveService.attendance.put(existingKey, record);
            updateCount++;
          }
        } else {
          await HiveService.attendance.put(record.compositeKey, record);
          insertCount++;
        }
      }

      debugPrint(
        '[SyncManager] pullAttendance selesai: '
        '$insertCount inserted, $updateCount updated dari ${cloudDocs.length} cloud docs.',
      );
    } catch (e) {
      debugPrint('[SyncManager] pullAttendance ❌ error: $e');
    }
  }

  // ─── PULL PERMISSIONS FROM CLOUD ───────────────────────────────────

  /// Pull semua PermissionRecord dari MongoDB dan merge ke Hive lokal.
  /// Menggunakan permissionId sebagai identifier unik.
  Future<void> pullPermissionsFromCloud() async {
    try {
      final cloudDocs = await MongoService.instance.findMany(
        collectionName: AppConstants.permissionsCollection,
      );

      if (cloudDocs.isEmpty) {
        debugPrint('[SyncManager] pullPermissions: tidak ada data di cloud.');
        return;
      }

      var insertCount = 0;
      var updateCount = 0;

      for (final doc in cloudDocs) {
        final record = PermissionRecord.fromMap(doc);
        final existing = HiveService.permissions.get(record.permissionId);

        if (existing != null) {
          if (record.updatedAt.isAfter(existing.updatedAt)) {
            await HiveService.permissions.put(record.permissionId, record);
            updateCount++;
          }
        } else {
          await HiveService.permissions.put(record.permissionId, record);
          insertCount++;
        }
      }

      debugPrint(
        '[SyncManager] pullPermissions selesai: '
        '$insertCount inserted, $updateCount updated dari ${cloudDocs.length} cloud docs.',
      );
    } catch (e) {
      debugPrint('[SyncManager] pullPermissions ❌ error: $e');
    }
  }

  // ─── PULL INVITATIONS FROM CLOUD ───────────────────────────────────

  /// Pull semua EventInvitation dari MongoDB dan merge ke Hive lokal.
  /// Menggunakan invitationId sebagai identifier unik.
  Future<void> pullInvitationsFromCloud() async {
    try {
      final cloudDocs = await MongoService.instance.findMany(
        collectionName: AppConstants.invitationsCollection,
      );

      if (cloudDocs.isEmpty) {
        debugPrint('[SyncManager] pullInvitations: tidak ada data di cloud.');
        return;
      }

      var insertCount = 0;
      var updateCount = 0;

      for (final doc in cloudDocs) {
        final invitation = EventInvitation.fromJson(doc);
        final existing = HiveService.invitations.get(invitation.invitationId);

        if (existing != null) {
          // Update jika respondedAt cloud lebih baru atau status berubah
          final cloudRespondedAt = invitation.respondedAt;
          final localRespondedAt = existing.respondedAt;
          final shouldUpdate = (cloudRespondedAt != null && localRespondedAt == null) ||
              (cloudRespondedAt != null &&
                  localRespondedAt != null &&
                  cloudRespondedAt.isAfter(localRespondedAt));
          if (shouldUpdate) {
            invitation.isSynced = true;
            await HiveService.invitations.put(invitation.invitationId, invitation);
            updateCount++;
          }
        } else {
          invitation.isSynced = true;
          await HiveService.invitations.put(invitation.invitationId, invitation);
          insertCount++;
        }
      }

      debugPrint(
        '[SyncManager] pullInvitations selesai: '
        '$insertCount inserted, $updateCount updated dari ${cloudDocs.length} cloud docs.',
      );
    } catch (e) {
      debugPrint('[SyncManager] pullInvitations ❌ error: $e');
    }
  }

  // ─── MANUAL TRIGGER (Alias) ──────────────────────────────────────

  /// Alias untuk syncAll() — kompatibilitas dengan kode lama.
  Future<void> syncPendingRecords() => syncAll();

  // ─── HELPERS ────────────────────────────────────────────────────

  void _updatePendingCount() {
    final attendancePending =
        HiveService.attendance.values.where((r) => !r.isSynced).length;
    final permissionPending =
        HiveService.permissions.values.where((p) => !p.isSynced).length;
    final eventPending =
        HiveService.events.values.where((e) => !e.isSynced).length;
    final invitationPending =
        HiveService.invitations.values.where((i) => !i.isSynced).length;

    pendingCount.value =
        attendancePending + permissionPending + eventPending + invitationPending;

    if (pendingCount.value > 0) {
      debugPrint(
        '[SyncManager] pending total: ${pendingCount.value} '
        '($attendancePending attendance + $permissionPending permission + '
        '$eventPending events + $invitationPending invitations)',
      );
    }
  }

  // ─── DISPOSE ────────────────────────────────────────────────────

  void dispose() {
    stopListening();
    pendingCount.dispose();
    isSyncing.dispose();
  }
}

/// Enum internal untuk hasil sync per record.
enum _SyncResult { success, duplicate, failed }