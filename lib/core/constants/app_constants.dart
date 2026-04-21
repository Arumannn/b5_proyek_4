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
  static const String permissionBox = 'permission_box';

  // ─── Hive TypeId Registry ────────────────────────
  // Setiap model Hive harus punya typeId unik. Jangan ubah nilai ini!
  static const int memberTypeId = 0;
  static const int eventTypeId = 1;
  static const int attendanceTypeId = 2;
  static const int permissionTypeId = 3;

  // ─── MongoDB Collections ─────────────────────────
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String attendanceCollection = 'attendance';

  // ─── QR Code Format ──────────────────────────────
  // Format QR: "PRASASTI:{nim}"
  static const String qrPrefix = 'PRASASTI:';

  // ─── UI / UX Constants ───────────────────────────
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxSyncRetries = 3;
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // ─── Role Definitions ────────────────────────────
  static const String roleAdmin = 'admin';
  static const String roleManager = 'manager';
  static const String roleOrganizer = 'organizer';
  static const String roleMember = 'member';

  static const List<String> allowedRoles = [
    roleAdmin,
    roleManager,
    roleOrganizer,
    roleMember,
  ];

  // ─── Default Admin Seeding ───────────────────────
  static const String defaultAdminNim = '241511038';
  static const String defaultAdminPassword = 'admin123';
  static const String defaultAdminName = 'Admin Utama';
  static const String defaultAdminDivision = 'Core';
  static const String adminSeedFlagKey = '__seed_admin_done__';

    // ─── Default Member Seeding ───────────────────────
  static const String defaultMemberNim = '241511039';
  static const String defaultMemberPassword = 'member123';
  static const String defaultMemberName = 'Member Biasa';
  static const String defaultMemberDivision = 'Anggota';
  static const String memberSeedFlagKey = '__seed_member_done__';

  // ─── Default Organizer Seeding ───────────────────────
  static const String defaultOrganizerNim = '241511040';
  static const String defaultOrganizerPassword = 'organizer123';
  static const String defaultOrganizerName = 'Organizer Biasa';
  static const String defaultOrganizerDivision = 'Kadep & Wakadep';
  static const String organizerSeedFlagKey = '__seed_organizer_done__';

  // Default Manager Seeding ──────────────────────────────────────
  static const String defaultManagerNim = '241511041';
  static const String defaultManagerPassword = 'manager123';
  static const String defaultManagerName = 'Manager Biasa';
  static const String defaultManagerDivision = 'Kadep & Wakadep';
  static const String managerSeedFlagKey = '__seed_manager_done__'; 


  // ─── Event Types ─────────────────────────────────
  static const List<String> eventTypes = ['Rapat', 'Acara', 'Kegiatan', 'Lainnya'];
}