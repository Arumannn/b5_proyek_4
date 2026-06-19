import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';

class EventPermission {
  EventPermission._();

  static bool _hasPermission(String roleOrJobTitle, String permissionKey) {
    final config = ConfigController.instance.activeConfig;

    for (final roleConfig in config.rolesConfig) {
      if (ConfigController.instance.roleOrJobMatchesConfigured(roleOrJobTitle, roleConfig)) {
        return ConfigController.instance.permissionListHas(roleConfig.permissions, permissionKey);
      }
    }
    return false;
  }

    static bool _isExecutive(String role) =>
      ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleExecutive);

    static bool _isManager(String role) =>
      ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleManager);

    static bool _isOrganizer(String role) =>
      ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleOrganizer);

    static bool _isMember(String role) =>
      ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleMember);

    static bool _isKnownRole(String role) =>
      _isExecutive(role) || _isManager(role) || _isOrganizer(role) || _isMember(role);

  // ─── Permission Keys (Standar Web Admin - CRUD Matrix) ───
  static const String keyCreateEvent = 'create_event';
  static const String keyReadEvent = 'read_event';
  static const String keyUpdateEvent = 'update_event';
  static const String keyDeleteEvent = 'delete_event';

  static const String keyCreateSubEvent = 'create_sub_event';
  static const String keyReadSubEvent = 'read_sub_event';
  static const String keyUpdateSubEvent = 'update_sub_event';
  static const String keyDeleteSubEvent = 'delete_sub_event';

  // ─── Pengecekan Izin (Dynamic) ────────────────────────────────────
  
  static bool canReadMainEvent(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyReadEvent);

  static bool canCreateMainEvent(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyCreateEvent);
  }

  static bool canUpdateMainEvent(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateEvent);
  }

  static bool canDeleteMainEvent(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyDeleteEvent);
  }

  static bool canReadSubEvent(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyReadSubEvent);

  static bool canCreateSubEvent(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyCreateSubEvent);
  }

  static bool canUpdateSubEvent(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateSubEvent);
  }

  static bool canDeleteSubEvent(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyDeleteSubEvent);
  }
}
