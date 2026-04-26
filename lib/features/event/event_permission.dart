import '../../core/constants/app_constants.dart';

class EventPermission {
  EventPermission._();

  // RBAC: Admin pada requirement dipetakan ke role Executive yang sudah ada di sistem.
  static String _normalizeRole(String role) => role.trim().toLowerCase();

  static String get _executiveRole => AppConstants.roleExecutive.toLowerCase();
  static String get _managerRole => AppConstants.roleManager.toLowerCase();
  static String get _organizerRole => AppConstants.roleOrganizer.toLowerCase();
  static String get _memberRole => AppConstants.roleMember.toLowerCase();

  static bool _isKnownRole(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _executiveRole ||
        normalized == _managerRole ||
        normalized == _organizerRole ||
        normalized == _memberRole;
  }

  static bool canReadMainEvent(String role) => _isKnownRole(role);
  static bool canCreateMainEvent(String role) => _normalizeRole(role) == _executiveRole;
  static bool canUpdateMainEvent(String role) => _normalizeRole(role) == _executiveRole;
  static bool canDeleteMainEvent(String role) => _normalizeRole(role) == _executiveRole;

  static bool canReadSubEvent(String role) => _isKnownRole(role);
  static bool canCreateSubEvent(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _executiveRole || normalized == _managerRole;
  }

  static bool canUpdateSubEvent(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _executiveRole || normalized == _managerRole;
  }

  static bool canDeleteSubEvent(String role) {
    final normalized = _normalizeRole(role);
    return normalized == _executiveRole || normalized == _managerRole;
  }
}
