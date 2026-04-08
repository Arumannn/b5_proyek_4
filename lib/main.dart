import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/services/hive_service.dart';
import 'core/services/mongo_service.dart';
import 'core/utils/network_status_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Step 1: Load .env ──────────────────────────────────────────
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Step 1: Environment variables loaded');

  // ── Step 2: Inisialisasi Hive ──────────────────────────────────
  await HiveService.init();
  debugPrint('✅ Step 2: HiveService initialized');

  // ── Step 3: Koneksi MongoDB Atlas ──────────────────────────────
  // Jalankan init() tapi tidak await — biar app tetap bisa jalan
  // meski internet mati (offline-first). Koneksi dicoba di background.
  MongoService.instance.init().then((connected) {
    if (connected) {
      debugPrint('✅ Step 3: MongoService connected to Atlas');
    } else {
      debugPrint('⚠️ Step 3: MongoService offline — app tetap berjalan (Hive mode)');
    }
  });

  // ── Step 4: Start network monitoring ──────────────────────────
  await NetworkStatusController.instance.startListening();
  debugPrint('✅ Step 4: NetworkStatusController started');

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B3A6B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF1B3A6B),
          foregroundColor: Colors.white,
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
      home: const _Week7SetupVerifier(),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// HALAMAN VERIFIKASI SETUP WEEK 7
// Akan diganti LoginView di Week 8.
// ──────────────────────────────────────────────────────────────────
class _Week7SetupVerifier extends StatefulWidget {
  const _Week7SetupVerifier();

  @override
  State<_Week7SetupVerifier> createState() => _Week7SetupVerifierState();
}

class _Week7SetupVerifierState extends State<_Week7SetupVerifier> {
  bool _isTestingMongo = false;
  String _mongoStatus = 'Belum diuji';
  bool _mongoSuccess = false;

  Future<void> _testMongoConnection() async {
    setState(() {
      _isTestingMongo = true;
      _mongoStatus = 'Menghubungkan ke MongoDB Atlas...\n(Maks ~15 detik)';
      _mongoSuccess = false;
    });

    final isConnected = await MongoService.instance.testConnection();

    if (mounted) {
      setState(() {
        _isTestingMongo = false;
        _mongoSuccess = isConnected;
        _mongoStatus = isConnected
            ? '✅ Berhasil terhubung ke MongoDB Atlas!\n'
                'Database: ${const String.fromEnvironment('MONGO_DATABASE', defaultValue: 'prasasti_db')}'
            : '❌ Gagal terhubung.\n\n'
                'Checklist:\n'
                '1. MONGO_URI di .env sudah diisi?\n'
                '2. <username> & <password> sudah diganti?\n'
                '3. IP 0.0.0.0/0 sudah di-allow di Atlas?\n'
                '4. Cluster tidak dalam kondisi paused?';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A6B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 64, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'PRASASTI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pusat Rekam Aktivitas dan Administrasi Terintegrasi',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Week 7 Checklist ──────────────────────────────
              const Text(
                'WEEK 7 — Setup Checklist',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _ChecklistItem(label: 'Flutter project initialized', isDone: true),
              _ChecklistItem(label: 'Dependencies terinstall (incl. mongo_dart)', isDone: true),
              _ChecklistItem(label: 'Clean Architecture folder structure', isDone: true),
              _ChecklistItem(label: 'HiveService initialized (Local DB)', isDone: true),
              _ChecklistItem(label: 'flutter_dotenv loaded (.env)', isDone: true),
              _ChecklistItem(label: 'NetworkStatusController started', isDone: true),
              _ChecklistItem(label: 'MongoService menggunakan mongo_dart driver', isDone: true),

              const SizedBox(height: 24),

              // ── MongoDB Connection Test ───────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _mongoSuccess
                        ? Colors.green.shade400
                        : _isTestingMongo
                            ? Colors.amber
                            : Colors.white24,
                    width: _isTestingMongo ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storage, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'MongoDB Atlas — mongo_dart Driver',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _mongoStatus,
                      style: TextStyle(
                        color: _mongoSuccess
                            ? Colors.greenAccent
                            : Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTestingMongo ? null : _testMongoConnection,
                        icon: _isTestingMongo
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _mongoSuccess ? Icons.check_circle : Icons.cloud_sync,
                              ),
                        label: Text(
                          _isTestingMongo
                              ? 'Menghubungkan...'
                              : _mongoSuccess
                                  ? 'Terhubung! Test Ulang'
                                  : 'Test Koneksi Atlas',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mongoSuccess
                              ? Colors.green.shade700
                              : const Color(0xFF2E86C1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Next Steps ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade600),
                ),
                child: const Text(
                  '📋 Checklist Week 7:\n'
                  '☐ Test koneksi MongoDB berhasil ✅\n'
                  '☐ Logbook Week 7 terisi\n'
                  '☐ Dokumen Spesifikasi dikumpulkan\n'
                  '☐ Repo GitHub aktif, commit merata\n'
                  '☐ Semua device anggota bisa flutter run\n\n'
                  '→ Next: Week 8 — Auth + Hive TypeAdapter + QR Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String label;
  final bool isDone;
  const _ChecklistItem({required this.label, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isDone ? Colors.greenAccent : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDone ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}