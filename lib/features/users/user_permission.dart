import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';

class UserPermission {
  UserPermission._();

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

  static const String keyReadMember = 'read_member';
  static const String keyCreateMember = 'create_member';
  static const String keyUpdateMember = 'update_member';
  static const String keyDeleteMember = 'delete_member';

  static bool canViewUsers(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyReadMember);
  }

  static bool canCreateUsers(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyCreateMember);
  }

  static bool canManageUsers(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateMember);
  }

  static bool canDeleteUsers(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyDeleteMember);
  }
}
