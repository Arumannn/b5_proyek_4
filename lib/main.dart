// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/login_view.dart';
import 'core/services/hive_service.dart';
import 'core/services/mongo_service.dart';
import 'core/utils/network_status_controller.dart';
import 'core/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/sync_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale date formatting for intl package (used across app)
  await initializeDateFormatting('id_ID');

  // Step 1: Load environment variables
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Step 1: .env loaded');

  // Step 2: Initialize Firebase
  await Firebase.initializeApp();
  debugPrint('✅ Step 2: Firebase initialized');

  // Step 3: Initialize Hive (local database)
  await HiveService.init();
  debugPrint('✅ Step 3: HiveService initialized — 4 boxes open');

  // Step 4: Connect MongoDB Atlas (BLOCKING — critical dependency untuk auth/sync)
  final mongoConnected = await MongoService.instance.init();
  if (mongoConnected) {
    debugPrint('✅ Step 4: MongoDB connected to Atlas');
  } else {
    debugPrint('⚠️ Step 4: MongoDB offline — app tetap berjalan (Hive mode)');
  }

  // Step 5: Start network monitoring
  await NetworkStatusController.instance.startListening();
  debugPrint('✅ Step 5: Network monitoring started');

  // Step 6: Seed default accounts (executive, member, organizer, manager)
  await AuthController.instance.initializeAuth();
  debugPrint('✅ Step 6: Default accounts seeded');

  // Step 7: FCM — stub untuk sekarang, implementasi penuh Week 11
  await FcmService.instance.init();

  // Step 8: Start SyncManager — auto-sync saat koneksi tersedia
  SyncManager.instance.startListening();
  debugPrint('✅ Step 8: SyncManager listening aktif');

  debugPrint('🚀 PRASASTI App starting...');
  runApp(const PRASASTIApp());
}

class PRASASTIApp extends StatelessWidget {
  const PRASASTIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginView(),
    );
  }
}
