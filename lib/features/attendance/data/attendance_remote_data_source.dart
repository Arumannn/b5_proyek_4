import '../../../core/constants/app_constants.dart';
import '../../../core/services/mongo_service.dart';

class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>?> findUserByNimOrQr(String nim, String normalizedIdentifier, String qrCodeValue) async {
    if (!MongoService.instance.isConnected) {
      final connected = await MongoService.instance.ensureConnected();
      if (!connected) return null;
    }

    var cloudDoc = await MongoService.instance.findOne(
      collectionName: AppConstants.usersCollection,
      filter: {'nim': nim},
    );
    cloudDoc ??= await MongoService.instance.findOne(
      collectionName: AppConstants.usersCollection,
      filter: {'nim': normalizedIdentifier},
    );
    cloudDoc ??= await MongoService.instance.findOne(
      collectionName: AppConstants.usersCollection,
      filter: {'qrCodeValue': qrCodeValue},
    );

    return cloudDoc;
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    if (!MongoService.instance.isConnected) {
      final connected = await MongoService.instance.ensureConnected();
      if (!connected) return [];
    }

    return await MongoService.instance.findMany(
      collectionName: AppConstants.usersCollection,
    );
  }

  Future<void> deleteAttendanceFromCloud(String compositeKey) async {
    if (!MongoService.instance.isConnected) {
      await MongoService.instance.ensureConnected();
    }
    await MongoService.instance.deleteOne(
      collectionName: AppConstants.attendanceCollection,
      filter: {'compositeKey': compositeKey},
    );
  }
}
