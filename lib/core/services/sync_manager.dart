import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../../models/attendance_record.dart';
import 'hive_service.dart';
import 'mongo_service.dart';

/// Sync Manager untuk sinkronisasi manual data lokal (Hive) ke MongoDB Atlas.
class SyncManager {
  static final SyncManager instance = SyncManager._internal();
  SyncManager._internal();

  bool _isListening = false;
  bool _isSyncing = false;

  void startListening() {
    if (_isListening) return;
    _isListening = true;
    debugPrint('[SyncManager] listening mode aktif (manual sync).');
  }

  Future<void> syncPendingRecords() async {
    if (_isSyncing) {
      debugPrint('[SyncManager] sync sedang berjalan, request baru diabaikan.');
      return;
    }

    _isSyncing = true;
    try {
      final List<AttendanceRecord> pendingRecords = HiveService.attendance.values
          .where((record) => !record.isSynced)
          .toList(growable: false);

      if (pendingRecords.isEmpty) {
        debugPrint('[SyncManager] tidak ada data pending untuk disinkronkan.');
        return;
      }

      debugPrint('[SyncManager] mulai sync ${pendingRecords.length} record pending.');

      for (final record in pendingRecords) {
        try {
          await MongoService.instance.insertOne(
            collectionName: AppConstants.attendanceCollection,
            document: record.toMap(),
          );

          record.isSynced = true;
          await record.save();
          debugPrint('[SyncManager] record ${record.recordId} berhasil disinkronkan.');
        } catch (e) {
          if (MongoService.isDuplicateKeyError(e)) {
            // Duplicate key (11000): data sudah ada di cloud, tandai synced.
            record.isSynced = true;
            await record.save();
            debugPrint(
              '[SyncManager] record ${record.recordId} duplicate (11000), ditandai synced.',
            );
            continue;
          }

          // Error selain duplicate dibiarkan pending untuk retry manual berikutnya.
          debugPrint(
            '[SyncManager] gagal sync record ${record.recordId}, tetap pending: $e',
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}