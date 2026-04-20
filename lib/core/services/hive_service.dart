import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../models/member_model.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';

/// Service untuk inisialisasi dan manajemen Hive local database.
///
/// RULES (WAJIB DIPATUHI):
/// - Panggil HiveService.init() HANYA SEKALI di main() sebelum runApp().
/// - Setelah init, akses box via getter: HiveService.members / .events / .attendance
/// - JANGAN panggil Hive.openBox() di tempat lain selain di sini.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  /// Inisialisasi Hive: register semua TypeAdapter, buka semua box.
  /// Dipanggil SEKALI di main() sebelum runApp().
  static Future<void> init() async {
    if (_initialized) {
      debugPrint('⚠️ HiveService.init() dipanggil lebih dari sekali — diabaikan.');
      return;
    }

    await Hive.initFlutter();

    // ── Daftarkan TypeAdapter (urutan sesuai typeId: 0, 1, 2) ────
    Hive.registerAdapter(MemberModelAdapter());      // typeId: 0
    Hive.registerAdapter(EventModelAdapter());        // typeId: 1
    Hive.registerAdapter(AttendanceRecordAdapter()); // typeId: 2

    // ── Buka semua box dengan tipe yang tepat ────────────────────
    await Hive.openBox<MemberModel>(AppConstants.memberBox);
    await Hive.openBox<EventModel>(AppConstants.eventBox);
    await Hive.openBox<AttendanceRecord>(AppConstants.attendanceBox);

    _initialized = true;
    debugPrint('✅ HiveService initialized');
    debugPrint('   Boxes: ${AppConstants.memberBox}, '
        '${AppConstants.eventBox}, ${AppConstants.attendanceBox}');
    debugPrint('   Members count : ${members.length}');
    debugPrint('   Events count  : ${events.length}');
    debugPrint('   Attendance cnt: ${attendance.length}');
  }

  // ─── Akses Box (selalu gunakan getter ini) ───────────────────
  static Box<MemberModel> get members {
    _assertInitialized();
    return Hive.box<MemberModel>(AppConstants.memberBox);
  }

  static Box<EventModel> get events {
    _assertInitialized();
    return Hive.box<EventModel>(AppConstants.eventBox);
  }

  static Box<AttendanceRecord> get attendance {
    _assertInitialized();
    return Hive.box<AttendanceRecord>(AppConstants.attendanceBox);
  }

  // ─── Utility ─────────────────────────────────────────────────
  static void _assertInitialized() {
    assert(
      _initialized,
      'HiveService belum diinisialisasi! Panggil HiveService.init() di main() dulu.',
    );
  }

  static bool get isInitialized => _initialized;

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
    debugPrint('🔒 HiveService closed');
  }
}