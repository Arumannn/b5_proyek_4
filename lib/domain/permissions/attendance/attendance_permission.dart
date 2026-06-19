import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';

class AttendancePermission {
  AttendancePermission._();

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

  static const String keyCreateScan = 'create_scan';
  static const String keyReadRekap = 'read_rekap';
  static const String keyUpdateKehadiran = 'update_kehadiran';
  static const String keyDeleteKehadiran = 'delete_kehadiran';

  static bool canCreateScan(String role) {
    if (_isExecutive(role) || _isManager(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyCreateScan);
  }

  static bool canEditStatus(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyUpdateKehadiran);
  }

  static bool canDeleteRecord(String role) {
    if (_isExecutive(role)) return true;
    if (_isKnownRole(role)) return false;
    return _hasPermission(role, keyDeleteKehadiran);
  }

  static bool canViewRecap(String role) => _isKnownRole(role) ? true : _hasPermission(role, keyReadRekap);

  static bool hasActionColumn(String role) => canEditStatus(role) || canDeleteRecord(role) || canCreateScan(role);
}
