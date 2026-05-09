import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:b5_proyek_4/core/constants/app_constants.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/core/services/mongo_service.dart';
import 'package:b5_proyek_4/core/services/sync_manager.dart';
import 'package:b5_proyek_4/models/attendance_record.dart';
import 'package:mongo_dart/mongo_dart.dart';

// Mock MongoService manually untuk kemudahan
class MockMongoService extends Mock implements MongoService {
  int insertOneCallCount = 0;
  bool shouldThrow = false;
  final bool _isConnected = true;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> ensureConnected() async {
    return _isConnected;
  }

  @override
  Future<WriteResult> insertOne({
    required String collectionName,
    required Map<String, dynamic> document,
  }) async {
    insertOneCallCount++;
    if (shouldThrow) {
      throw Exception('Simulated Database Down / Network Error');
    }
    return MockWriteResult();
  }
}

class MockWriteResult extends Mock implements WriteResult {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late MockMongoService mockMongoService;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return Directory.systemTemp.path;
    });

    await HiveService.init();
    
    // Override delay to make tests run faster
    AppConstants.syncRetryDelay = const Duration(milliseconds: 100);
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() async {
    await HiveService.attendance.clear();
    
    // Inject Mock MongoService
    mockMongoService = MockMongoService();
    MongoService.instance = mockMongoService;
    
    // Reset state
    SyncManager.instance.pendingCount.value = 0;
  });

  group('Recovery Testing - Network Failure & DB Down', () {
    test('Attendance tetap isSynced=false jika offline / DB Down dan akan retry', () async {
      // 1. Setup data offline
      final record = AttendanceRecord(
        recordId: 'rec-1',
        eventId: 'event-1',
        memberId: 'member-1',
        timestamp: DateTime.now(),
        compositeKey: 'event-1_member-1',
      );
      record.isSynced = false;
      await HiveService.attendance.put(record.recordId, record);

      expect(HiveService.attendance.values.first.isSynced, false);

      // 2. Simulate DB Down (Throw exception on insertOne)
      mockMongoService.shouldThrow = true;

      // 3. Trigger sync
      await SyncManager.instance.syncPendingAttendance();

      // 4. Verify retry mechanism happened (maxSyncRetries = 3)
      expect(mockMongoService.insertOneCallCount, AppConstants.maxSyncRetries);
      
      // Data should still be pending
      final pendingRecord = HiveService.attendance.get(record.recordId);
      expect(pendingRecord?.isSynced, false);
    });

    test('Attendance sync sukses ketika DB kembali normal setelah sempat down', () async {
      // 1. Setup data
      final record = AttendanceRecord(
        recordId: 'rec-2',
        eventId: 'event-2',
        memberId: 'member-2',
        timestamp: DateTime.now(),
        compositeKey: 'event-2_member-2',
      );
      record.isSynced = false;
      await HiveService.attendance.put(record.recordId, record);

      // 2. Simulate DB is back ONLINE (no exceptions)
      mockMongoService.shouldThrow = false;
      mockMongoService.insertOneCallCount = 0; // reset

      // 3. Trigger sync
      await SyncManager.instance.syncPendingAttendance();

      // 4. Verify sync success
      expect(mockMongoService.insertOneCallCount, 1); // Only took 1 attempt
      
      final syncedRecord = HiveService.attendance.get(record.recordId);
      expect(syncedRecord?.isSynced, true);
    });
  });
}
