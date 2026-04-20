import 'package:flutter/foundation.dart';

/// FCM Service — Implementasi penuh: Week 11
///
/// Yang akan diimplementasi di Week 11:
///   init(): Firebase.initializeApp() + minta permission notifikasi
///   getFcmToken(): ambil token perangkat → simpan ke Hive & MongoDB
///   setupMessageHandlers(): foreground, background, terminated state
///   sendNotification(): Admin → Member saat izin divalidasi
class FcmService {
  static final FcmService instance = FcmService._internal();
  FcmService._internal();

  Future<void> init() async {
    debugPrint('⏳ FcmService: init() — implementasi Week 11');
  }

  Future<String?> getFcmToken() async {
    debugPrint('⏳ FcmService: getFcmToken() — implementasi Week 11');
    return null;
  }
}