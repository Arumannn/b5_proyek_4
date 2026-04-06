import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  // Nama box sebagai konstanta agar tidak typo
  static const String memberBox = 'members';
  static const String eventBox = 'events';
  static const String attendanceBox = 'attendance';

  /// Inisialisasi Hive dan buka semua box yang diperlukan.
  /// Dipanggil sekali di main() sebelum runApp().
  static Future<void> init() async {
    await Hive.initFlutter();
    // Adapter akan didaftarkan di sini setelah model dibuat (Week 8)
    // await Hive.openBox<Member>(memberBox);
    // await Hive.openBox<Event>(eventBox);
    // await Hive.openBox<AttendanceRecord>(attendanceBox);
  }

  /// Tutup semua box saat app ditutup (opsional, Hive handle otomatis)
  static Future<void> closeAll() async {
    await Hive.close();
  }
}