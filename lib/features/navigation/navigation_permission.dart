import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';

class NavigationPermission {
  NavigationPermission._();

  static bool _hasPermission(String roleOrJobTitle, String permissionKey) {
    final config = ConfigController.instance.activeConfig;

    for (final roleConfig in config.rolesConfig) {
      final matches = ConfigController.instance.roleOrJobMatchesConfigured(roleOrJobTitle, roleConfig);
      // Debug logging to trace RBAC decisions at runtime
      // ignore: avoid_print
      print('[NavigationPermission] checking="$roleOrJobTitle" against="${roleConfig.roleName}" -> $matches for key=$permissionKey');
      if (matches) {
        final allowed = ConfigController.instance.permissionListHas(roleConfig.permissions, permissionKey);
        // ignore: avoid_print
        print('[NavigationPermission] permissionResult for ${roleConfig.roleName}: $allowed');
        return allowed;
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

  static const String keyShowHomeTab = 'read_dashboard';
  static const String keyShowEventTab = 'read_event';
  static const String keyShowUsersTab = 'read_member';
  static const String keyShowReportsTab = 'read_rekap';
  static const String keyShowHistoryTab = 'read_kehadiran';

  static bool showHomeTab(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyShowHomeTab);

  static bool showEventTab(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyShowEventTab);

  static bool showUsersTab(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isOrganizer(role) || _isMember(role)) return false;
    return _hasPermission(role, keyShowUsersTab);
  }

  static bool showReportsTab(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isOrganizer(role) || _isMember(role)) return false;
    return _hasPermission(role, keyShowReportsTab);
  }

  static bool showHistoryTab(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyShowHistoryTab);
}
