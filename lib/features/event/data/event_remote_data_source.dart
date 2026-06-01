import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/mongo_service.dart';

class EventRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchEventsFromCloud() async {
    if (!MongoService.instance.isConnected) {
      final connected = await MongoService.instance.ensureConnected();
      if (!connected) return [];
    }

    final cloudDocs = await MongoService.instance.findMany(
      collectionName: AppConstants.eventsCollection,
    );

    return cloudDocs.map(_sanitizeMongoDoc).toList();
  }

  Future<bool> upsertEventToCloud(Map<String, dynamic> payload) async {
    if (!MongoService.instance.isConnected) {
      final connected = await MongoService.instance.ensureConnected();
      if (!connected) return false;
    }

    final eventId = payload['eventId']?.toString();
    if (eventId == null || eventId.isEmpty) return false;

    try {
      final existing = await MongoService.instance.findOne(
        collectionName: AppConstants.eventsCollection,
        filter: {'eventId': eventId},
      );

      if (existing == null) {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.eventsCollection,
          document: payload,
        );
      } else {
        await MongoService.instance.updateOne(
          collectionName: AppConstants.eventsCollection,
          filter: {'eventId': eventId},
          updateFields: payload,
        );
      }
      return true;
    } catch (e) {
      if (MongoService.isDuplicateKeyError(e)) {
        return true; // Treat duplicate as success for upsert
      }
      rethrow;
    }
  }

  Map<String, dynamic> _sanitizeMongoDoc(Map<String, dynamic> doc) {
    final clean = Map<String, dynamic>.from(doc);
    clean.remove('_id'); // ObjectId tidak bisa diparse Dart langsung
    return clean;
  }
}
