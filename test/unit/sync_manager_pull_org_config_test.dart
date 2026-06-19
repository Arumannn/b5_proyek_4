import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:b5_proyek_4/data/services/mongo_service.dart';
import 'package:b5_proyek_4/data/services/sync_manager.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';

class MockMongoService extends Mock implements MongoService {
  @override
  Future<bool> ensureConnected() async => true;

  @override
  bool get isConnected => true;

  @override
  Future<List<Map<String, dynamic>>> findMany({
    required String collectionName,
    Map<String, dynamic>? filter,
    Map<String, dynamic>? sort,
    int? limit,
  }) async {
    if (collectionName == 'roles') {
      return [
        {'name': 'CustomRole', 'permissions': ['p1', 'p2'], 'jabatan': ['J1', 'J2']}
      ];
    }
    if (collectionName == 'event-types' || collectionName == 'eventtypes') {
      return [
        {'name': 'Workshop'},
        {'name': 'Seminar'}
      ];
    }
    return [];
  }

  // Minimal stubs for other MongoService methods not used in this test
  @override
  Future<WriteResult> insertOne({required String collectionName, required Map<String, dynamic> document}) {
    throw UnimplementedError();
  }

  @override
  Future<BulkWriteResult> insertMany({required String collectionName, required List<Map<String, dynamic>> documents}) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> findOne({required String collectionName, required Map<String, dynamic> filter}) {
    throw UnimplementedError();
  }

  @override
  Future<int> updateOne({required String collectionName, required Map<String, dynamic> filter, required Map<String, dynamic> updateFields}) {
    throw UnimplementedError();
  }

  @override
  Future<int> deleteOne({required String collectionName, required Map<String, dynamic> filter}) {
    throw UnimplementedError();
  }

  @override
  Future<int> count({required String collectionName, Map<String, dynamic>? filter}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> init() {
    throw UnimplementedError();
  }

  @override
  Future<bool> testConnection() {
    throw UnimplementedError();
  }

  // ensureConnected already provided above without params

  @override
  Future<void> close() {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  late Directory _tmpDir;

  setUpAll(() async {
    _tmpDir = Directory.systemTemp.createTempSync('hive_syncmgr_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return _tmpDir.path;
      }
      return _tmpDir.path;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (methodCall) async {
      if (methodCall.method == 'check') return <String>['none'];
      return null;
    });

    await HiveService.init();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    try {
      if (await _tmpDir.exists()) await _tmpDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await HiveService.organizationConfigs.clear();
    await HiveService.members.clear();
  });

  test('pullOrganizationConfigFromCloud saves config to Hive', () async {
    // Arrange
    final member = MemberModel(
      nama: 'OrgUser',
      nim: 'O1',
      divisi: 'Org',
      role: 'member',
      password: 'pw',
      qrCodeValue: 'qr',
      organizationId: 'org-1',
    );
    await HiveService.members.put(member.nim, member);
    AuthController.instance.currentUser.value = member;

    final mock = MockMongoService();
    MongoService.instance = mock;

    // Act
    await SyncManager.instance.pullOrganizationConfigFromCloud();

    // Assert
    final cfg = HiveService.organizationConfigs.get('org-1');
    expect(cfg, isNotNull);
    expect(cfg?.eventTypes, contains('Workshop'));
    expect(cfg?.rolesConfig.any((r) => r.roleName == 'CustomRole'), isTrue);
  });
}
