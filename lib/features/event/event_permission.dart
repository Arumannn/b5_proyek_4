import '../../core/controllers/config_controller.dart';

class EventPermission {
  EventPermission._();

  static bool _hasPermission(String roleOrJobTitle, String permissionKey) {
    final normalizedJob = roleOrJobTitle.trim().toLowerCase();
    final config = ConfigController.instance.activeConfig;

    for (final roleConfig in config.rolesConfig) {
      if (roleConfig.roleName.toLowerCase() == normalizedJob) {
        return roleConfig.permissions.contains(permissionKey);
      }
    }
    return false;
  }

  // ─── Permission Keys (Standar yang disepakati dengan Web Admin) ───
  static const String keyReadMainEvent = 'read_main_event';
  static const String keyCreateMainEvent = 'create_main_event';
  static const String keyUpdateMainEvent = 'update_main_event';
  static const String keyDeleteMainEvent = 'delete_main_event';

  static const String keyReadSubEvent = 'read_sub_event';
  static const String keyCreateSubEvent = 'create_sub_event';
  static const String keyUpdateSubEvent = 'update_sub_event';
  static const String keyDeleteSubEvent = 'delete_sub_event';

  // ─── Pengecekan Izin (Dynamic) ────────────────────────────────────
  
  // Asumsi: Semua pengguna yang terdaftar berhak melihat event secara default
  static bool canReadMainEvent(String role) => true; 
  
  static bool canCreateMainEvent(String role) => _hasPermission(role, keyCreateMainEvent);
  static bool canUpdateMainEvent(String role) => _hasPermission(role, keyUpdateMainEvent);
  static bool canDeleteMainEvent(String role) => _hasPermission(role, keyDeleteMainEvent);

  static bool canReadSubEvent(String role) => true;
  
  static bool canCreateSubEvent(String role) => _hasPermission(role, keyCreateSubEvent);
  static bool canUpdateSubEvent(String role) => _hasPermission(role, keyUpdateSubEvent);
  static bool canDeleteSubEvent(String role) => _hasPermission(role, keyDeleteSubEvent);
}
