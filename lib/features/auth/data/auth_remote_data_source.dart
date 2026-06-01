import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/mongo_service.dart';

class AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSource()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: AppConstants.networkTimeout,
            receiveTimeout: AppConstants.networkTimeout,
            sendTimeout: AppConstants.networkTimeout,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  Future<bool> upsertUserToCloud(Map<String, dynamic> payload) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();
    final nim = (payload['nim'] ?? '').toString().trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.put(
          '$baseUrl/users/$nim',
          data: payload,
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          debugPrint('[AuthRemoteDataSource][upsert] cloud API success status=$statusCode');
          return true;
        }

        debugPrint(
          '[AuthRemoteDataSource][upsert] cloud API non-success status=$statusCode',
        );
      } catch (e) {
        debugPrint(
          '[AuthRemoteDataSource][upsert] cloud API failed, fallback to MongoService: $e',
        );
      }
    }

    // Check if MongoDB is connected before attempting operations
    if (!MongoService.instance.isConnected) {
      debugPrint('[AuthRemoteDataSource][upsert] MongoDB tidak terkoneksi, skip upsert');
      return false;
    }

    try {
      final existing = await MongoService.instance.findOne(
        collectionName: AppConstants.usersCollection,
        filter: {'nim': nim},
      );

      if (existing == null) {
        await MongoService.instance.insertOne(
          collectionName: AppConstants.usersCollection,
          document: payload,
        );
      } else {
        await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'nim': nim},
          updateFields: payload,
        );
      }

      debugPrint('[AuthRemoteDataSource][upsert] mongo_dart upsert success');
      return true;
    } catch (e) {
      if (MongoService.isDuplicateKeyError(e)) {
        debugPrint(
          '[AuthRemoteDataSource][upsert] duplicate user on cloud, treated as synced',
        );
        return true;
      }
      debugPrint('[AuthRemoteDataSource][upsert] mongo_dart upsert failed: $e');
      return false;
    }
  }

  Future<bool> deleteUserFromCloud(String nim) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.delete(
          '$baseUrl/users/$nim',
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          return true;
        }
      } catch (e) {
        debugPrint(
          '[AuthRemoteDataSource][delete] cloud API failed, fallback to MongoService: $e',
        );
      }
    }

    try {
      await MongoService.instance.deleteOne(
        collectionName: AppConstants.usersCollection,
        filter: {'nim': nim},
      );
      return true;
    } catch (e) {
      debugPrint('[AuthRemoteDataSource][delete] mongo_dart delete failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchUserFromCloud(String nim) async {
    final baseUrl = (dotenv.env['ATLAS_API_BASE_URL'] ?? '').trim();
    final apiKey = (dotenv.env['ATLAS_API_KEY'] ?? '').trim();

    if (baseUrl.isNotEmpty) {
      try {
        final headers = <String, dynamic>{};
        if (apiKey.isNotEmpty) {
          headers['x-api-key'] = apiKey;
        }

        final response = await _dio.get(
          '$baseUrl/users',
          queryParameters: {'nim': nim},
          options: Options(headers: headers),
        );

        final statusCode = response.statusCode ?? 500;
        if (statusCode >= 200 && statusCode < 300) {
          final doc = _extractUserMapFromApiResponse(response.data);
          if (doc != null) {
            debugPrint('[AuthRemoteDataSource][fetch] cloud API hit');
            return doc;
          }
        }
      } catch (e) {
        debugPrint(
          '[AuthRemoteDataSource][fetch] cloud API read failed, fallback to MongoService: $e',
        );
      }
    }

    // Check if MongoDB is connected before attempting to query
    if (!MongoService.instance.isConnected) {
      debugPrint('[AuthRemoteDataSource][fetch] MongoDB tidak terkoneksi, skipping mongo_dart query');
      return null;
    }

    try {
      final doc = await MongoService.instance.findOne(
        collectionName: AppConstants.usersCollection,
        filter: {'nim': nim},
      );

      if (doc != null) {
        debugPrint('[AuthRemoteDataSource][fetch] mongo_dart cloud hit');
      }
      return doc;
    } catch (e) {
      debugPrint('[AuthRemoteDataSource][fetch] mongo_dart read failed: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    if (!MongoService.instance.isConnected) {
      return [];
    }
    try {
      final users = await MongoService.instance.findMany(
        collectionName: AppConstants.usersCollection,
      );
      return users;
    } catch (e) {
      debugPrint('[AuthRemoteDataSource][fetchAllUsers] failed: $e');
      return [];
    }
  }
  
  Future<void> updateUserFCMToken(String nim, String token) async {
    if (!MongoService.instance.isConnected) return;
    try {
       await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'nim': nim},
          updateFields: {'fcmToken': token},
        );
    } catch(e) {
       debugPrint('[AuthRemoteDataSource][fcmToken] update failed: $e');
    }
  }

  Future<void> normalizeRolesInCloud(String Function(String) normalizeRoleFunc) async {
    if (!MongoService.instance.isConnected) return;
    try {
      final users = await fetchAllUsers();
      var changedCount = 0;
      for (final user in users) {
        final nim = (user['nim'] ?? '').toString().trim();
        if (nim.isEmpty) continue;
        final normalizedRole = normalizeRoleFunc((user['role'] ?? '').toString());
        if (normalizedRole == (user['role'] ?? '').toString()) {
          continue;
        }
        await MongoService.instance.updateOne(
          collectionName: AppConstants.usersCollection,
          filter: {'nim': nim},
          updateFields: {'role': normalizedRole},
        );
        changedCount++;
      }
      if (changedCount > 0) {
        debugPrint(
          '[AuthRemoteDataSource][normalizeRole] cloud roles normalized: $changedCount user(s).',
        );
      }
    } catch (e) {
      debugPrint('[AuthRemoteDataSource][normalizeRole] cloud normalization skipped: $e');
    }
  }

  Map<String, dynamic>? _extractUserMapFromApiResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
      }
      if (data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
      }
      return data;
    }

    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) {
        return Map<String, dynamic>.from(first);
      }
      if (first is Map) {
        return first.map((k, v) => MapEntry(k.toString(), v));
      }
    }

    return null;
  }
}
