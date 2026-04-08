/// Konstanta global untuk seluruh aplikasi PRASASTI.
/// Semua string literal penting dipusatkan di sini — hindari typo.
class AppConstants {
  AppConstants._(); // prevent instantiation

  // ─── Identitas Aplikasi ──────────────────────────
  static const String appName = 'PRASASTI';
  static const String appFullName =
      'Pusat Rekam Aktivitas dan Administrasi Terintegrasi';
  static const String appVersion = '1.0.0';

  // ─── Hive Box Names ──────────────────────────────
  // SELALU gunakan konstanta ini, jangan ketik ulang string-nya manual.
  static const String memberBox = 'member_box';
  static const String eventBox = 'event_box';
  static const String attendanceBox = 'attendance_box';

  // ─── Hive TypeId Registry ────────────────────────
  // Setiap model Hive harus punya typeId unik. Jangan ubah nilai ini!
  static const int memberTypeId = 0;
  static const int eventTypeId = 1;
  static const int attendanceTypeId = 2;

  // ─── MongoDB Collections ─────────────────────────
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String attendanceCollection = 'attendance';

  // ─── QR Code Format ──────────────────────────────
  // Format QR: "PRASASTI:{memberId}"
  static const String qrPrefix = 'PRASASTI:';

  // ─── UI / UX Constants ───────────────────────────
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // ─── Role Definitions ────────────────────────────
  static const String roleAdmin = 'Admin';
  static const String roleMember = 'Member';

  // ─── Event Types ─────────────────────────────────
  static const List<String> eventTypes = ['Rapat', 'Acara', 'Kegiatan', 'Lainnya'];
}