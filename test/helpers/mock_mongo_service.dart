import 'package:mockito/mockito.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:b5_proyek_4/data/services/mongo_service.dart';

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

  @override
  Future<Map<String, dynamic>?> findOne({
    required String collectionName,
    required Map<String, dynamic> filter,
  }) async {
    return null;
  }
}

class MockWriteResult extends Mock implements WriteResult {}
