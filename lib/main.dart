import 'package:flutter/material.dart';
import 'services/hive_service.dart';

void main() async {
  // Pastikan Flutter binding siap sebelum operasi async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive
  await HiveService.init();

  runApp(const PRASASTIApp());
}

class PRASASTIApp extends StatelessWidget {
  const PRASASTIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRASASTI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3A6B), // Biru gelap PRASASTI
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      // Sementara arahkan ke halaman placeholder
      // Akan diganti dengan LoginScreen di Week 8
      home: const _PlaceholderHome(),
    );
  }
}

/// Halaman placeholder sementara sampai LoginScreen dibuat di Week 8.
/// Ini BUKAN bagian dari arsitektur final — hanya untuk verifikasi setup.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A6B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'PRASASTI',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pusat Rekam Aktivitas dan Sistem Administrasi Terintegrasi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Kick Off Setup Completed - Wait For Our Launch!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}