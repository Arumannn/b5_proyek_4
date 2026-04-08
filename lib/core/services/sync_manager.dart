import 'package:flutter/foundation.dart';

/// Sync Manager — Implementasi penuh: Week 11
///
/// Yang akan diimplementasi di Week 11 menggunakan mongo_dart:
///
///   startListening(): Listen connectivity_plus → trigger sync
///   saat status jaringan berubah dari offline → online.
///
///   syncPendingRecords():
///   1. Query Hive: ambil semua AttendanceRecord dengan isSynced=false
///   2. Untuk setiap record:
///      a. Coba insertOne ke MongoDB Atlas via MongoService
///      b. Sukses → update isSynced=true di Hive (record.save())
///      c. Duplicate key error (11000) → tandai synced=true
///         (data sudah ada di cloud dari perangkat lain)
///      d. Error lain → biarkan pending, retry berikutnya
///   3. Retry logic: maks 3x dengan delay 5 detik
///
/// Anti-duplikasi dijamin oleh unique index MongoDB pada field compositeKey.
/// Setup unique index di Week 11:
///   db.attendance.createIndex({ compositeKey: 1 }, { unique: true })
class SyncManager {
  static final SyncManager instance = SyncManager._internal();
  SyncManager._internal();

  bool _isListening = false;

  void startListening() {
    if (_isListening) return;
    _isListening = true;
    debugPrint('⏳ SyncManager: startListening() — implementasi Week 11');
  }

  Future<void> syncPendingRecords() async {
    debugPrint('⏳ SyncManager: syncPendingRecords() — implementasi Week 11');
  }
}