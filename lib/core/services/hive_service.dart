import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

// TODO Week 8: Uncomment setelah model selesai dibuat & build_runner dijalankan
// import '../../models/member_model.dart';
// import '../../models/event_model.dart';
// import '../../models/attendance_record.dart';

/// Service untuk inisialisasi dan manajemen Hive local database.
///
/// RULES (WAJIB DIPATUHI):
/// - Panggil HiveService.init() HANYA SEKALI di main() sebelum runApp().
/// - Setelah init, gunakan HiveService.members / .events / .attendance
///   untuk akses box — jangan panggil Hive.openBox() lagi di tempat lain!
class HiveService {
  HiveService._(); // prevent instantiation

  static bool _initialized = false;

  /// Inisialisasi Hive dan buka semua box yang dibutuhkan.
  /// Dipanggil SEKALI di main() sebelum runApp().
  static Future<void> init() async {
    if (_initialized) {
      debugPrint('⚠️ HiveService.init() dipanggil lebih dari sekali — diabaikan.');
      return;
    }

    await Hive.initFlutter();

    // ── TODO Week 8: Daftarkan TypeAdapter setelah model dibuat ──
    // Urutan pendaftaran harus sesuai typeId (0, 1, 2)
    // Hive.registerAdapter(MemberModelAdapter());      // typeId: 0
    // Hive.registerAdapter(EventModelAdapter());        // typeId: 1
    // Hive.registerAdapter(AttendanceRecordAdapter()); // typeId: 2

    // ── TODO Week 8: Buka box dengan tipe yang spesifik ──
    // await Hive.openBox<MemberModel>(AppConstants.memberBox);
    // await Hive.openBox<EventModel>(AppConstants.eventBox);
    // await Hive.openBox<AttendanceRecord>(AppConstants.attendanceBox);

    // Sementara buka sebagai dynamic box (diubah ke typed di Week 8)
    await Hive.openBox(AppConstants.memberBox);
    await Hive.openBox(AppConstants.eventBox);
    await Hive.openBox(AppConstants.attendanceBox);

    _initialized = true;
    debugPrint('✅ HiveService initialized — boxes: member, event, attendance');
  }

  // ─── Akses Box (Gunakan ini, bukan Hive.box() langsung) ─────
  static Box get members {
    _assertInitialized();
    return Hive.box(AppConstants.memberBox);
  }

  static Box get events {
    _assertInitialized();
    return Hive.box(AppConstants.eventBox);
  }

  static Box get attendance {
    _assertInitialized();
    return Hive.box(AppConstants.attendanceBox);
  }

  // ─── Utility ─────────────────────────────────────
  static void _assertInitialized() {
    assert(
      _initialized,
      'HiveService belum diinisialisasi! Panggil HiveService.init() di main() dulu.',
    );
  }

  /// Tutup semua box (opsional, Hive biasanya handle otomatis).
  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
    debugPrint('🔒 HiveService closed');
  }
}