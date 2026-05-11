
import '../constants/app_constants.dart';
/// Policy hak akses fitur rekap kehadiran berdasarkan role.
class AttendanceRolePolicy {
  final bool canEditStatus;
  final bool canDeleteRecord;
  const AttendanceRolePolicy({
    required this.canEditStatus,
    required this.canDeleteRecord,
  });
  bool get hasActionColumn => canEditStatus || canDeleteRecord;
  factory AttendanceRolePolicy.forRole(String role) {
    switch (role) {
      case AppConstants.roleExecutive:
        return const AttendanceRolePolicy(
          canEditStatus: true,
          canDeleteRecord: true,
        );
      case AppConstants.roleManager:
        return const AttendanceRolePolicy(
          canEditStatus: true,
          canDeleteRecord: true,
        );
      case AppConstants.roleOrganizer:
        return const AttendanceRolePolicy(
          canEditStatus: false,
          canDeleteRecord: false,
        );
      default:
        return const AttendanceRolePolicy(
          canEditStatus: false,
          canDeleteRecord: false,
        );
    }
  }
  static const AttendanceRolePolicy executive = AttendanceRolePolicy(
    canEditStatus: true,
    canDeleteRecord: true,
  );
  static const AttendanceRolePolicy manager = AttendanceRolePolicy(
    canEditStatus: true,
    canDeleteRecord: true,
  );
  static const AttendanceRolePolicy organizer = AttendanceRolePolicy(
    canEditStatus: false,
    canDeleteRecord: false,
  );
}
