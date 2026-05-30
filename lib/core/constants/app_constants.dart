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
  static const String pendingUserUpsertBox = 'pending_user_upsert_box';
  static const String pendingUserDeleteBox = 'pending_user_delete_box';
  static const String notulensiBox = 'notulensi_box';
  static const String organizationConfigBox = 'organization_config_box';

  // ─── Hive TypeId Registry ────────────────────────
  // Setiap model Hive harus punya typeId unik. Jangan ubah nilai ini!
  static const int memberTypeId = 0;
  static const int eventTypeId = 1;
  static const int attendanceTypeId = 2;
  static const int permissionTypeId = 3;
  static const int notulensiTypeId = 8;
  static const int roleConfigTypeId = 9;
  static const int organizationConfigTypeId = 10;

  // ─── MongoDB Collections ─────────────────────────
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String attendanceCollection = 'attendance';
  static const String permissionsCollection = 'permissions';
  static const String invitationsCollection = 'invitations';
  static const String organizationConfigsCollection = 'organization_configs';

  // ─── QR Code Format ──────────────────────────────
  // Format QR: "PRASASTI:{nim}"
  static const String qrPrefix = 'PRASASTI:';

  // ─── UI / UX Constants ───────────────────────────
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration networkTimeout = Duration(seconds: 15);
  static const int maxSyncRetries = 3;
  static Duration syncRetryDelay = const Duration(seconds: 5);

  // ─── Role Definitions ────────────────────────────
  static const String roleExecutive = 'executive';
  static const String roleManager = 'manager';
  static const String roleOrganizer = 'organizer';
  static const String roleMember = 'member';

  static const List<String> allowedRoles = [
    roleExecutive,
    roleManager,
    roleOrganizer,
    roleMember,
  ];

  // ─── Default Executive Seeding ───────────────────────
  static const String defaultExecutiveNim = '38';
  static const String defaultExecutivePassword = '123';
  static const String defaultExecutiveName = 'Executive Utama';
  static const String defaultExecutiveDivision = 'HEXA';
  static const String executiveSeedFlagKey = '__seed_executive_done__';

  // ─── Default Member Seeding ───────────────────────
  static const String defaultMemberNim = '39';
  static const String defaultMemberPassword = '123';
  static const String defaultMemberName = 'Member Biasa';
  static const String defaultMemberDivision = 'Anggota';
  static const String memberSeedFlagKey = '__seed_member_done__';

  // ─── Default Organizer Seeding ───────────────────────
  static const String defaultOrganizerNim = '40';
  static const String defaultOrganizerPassword = '123';
  static const String defaultOrganizerName = 'Organizer Biasa';
  static const String defaultOrganizerDivision = 'Kadep & Wakadep';
  static const String organizerSeedFlagKey = '__seed_organizer_done__';

  // Default Manager Seeding ──────────────────────────────────────
  static const String defaultManagerNim = '41';
  static const String defaultManagerPassword = '123';
  static const String defaultManagerName = 'Manager Biasa';
  static const String defaultManagerDivision = 'Administrasi dan Kesekretariatan';
  static const String managerSeedFlagKey = '__seed_manager_done__';
}
