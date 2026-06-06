import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';

class DashboardPermission {
  DashboardPermission._();

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
  static const String keyReadDashboard = 'read_dashboard';
  static const String keyUpdateMember = 'update_member'; // Assuming manage translates to update
  static const String keyUpdateEvent = 'update_event';
  static const String keyReadKehadiran = 'read_kehadiran';

  // Executive dashboard untuk Executive dan Manager.
  static bool showExecutiveAdmin(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isOrganizer(role) || _isMember(role)) return false;
    return _hasPermission(role, keyReadDashboard);
  }
  
  // Tampilan member menjadi fallback untuk role selain Executive.
  static bool showMemberHome(String role) => !showExecutiveAdmin(role);

  static bool canManageMembers(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateMember);
  }

  static bool canManageEvents(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateEvent);
  }

  static bool canManageInvitations(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateEvent);
  }

  static bool canViewAttendance(String role) {
    if (_isExecutive(role) || _isManager(role) || _isOrganizer(role) || _isMember(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyReadKehadiran);
  }
}
