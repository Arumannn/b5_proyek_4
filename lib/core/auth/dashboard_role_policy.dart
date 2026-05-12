import '../constants/app_constants.dart';

/// Policy hak akses fitur dashboard berdasarkan role.
/// Menentukan komponen apa yang bisa diakses untuk setiap role.
class DashboardRolePolicy {
  final bool showExecutiveAdmin; // Stats, menu admin
  final bool showMemberHome; // Invitation, QR, events
  final bool canManageMembers;
  final bool canManageEvents;
  final bool canManageInvitations;
  final bool canViewAttendance;

  const DashboardRolePolicy({
    required this.showExecutiveAdmin,
    required this.showMemberHome,
    required this.canManageMembers,
    required this.canManageEvents,
    required this.canManageInvitations,
    required this.canViewAttendance,
  });

  factory DashboardRolePolicy.forRole(String role) {
    final normalized = role.trim().toLowerCase();

    // Executive / Manager / Admin
    if (normalized == AppConstants.roleExecutive.toLowerCase() ||
        normalized == 'executive' ||
        normalized == 'eksekutif' ||
        normalized == 'admin' ||
        normalized == AppConstants.roleManager.toLowerCase()) {
      return const DashboardRolePolicy(
        showExecutiveAdmin: true,
        showMemberHome: false,
        canManageMembers: true,
        canManageEvents: true,
        canManageInvitations: true,
        canViewAttendance: true,
      );
    }

    // Member, Organizer, dan role lainnya
    return const DashboardRolePolicy(
      showExecutiveAdmin: false,
      showMemberHome: true,
      canManageMembers: false,
      canManageEvents: false,
      canManageInvitations: false,
      canViewAttendance: true,
    );
  }

  static const DashboardRolePolicy executive = DashboardRolePolicy(
    showExecutiveAdmin: true,
    showMemberHome: false,
    canManageMembers: true,
    canManageEvents: true,
    canManageInvitations: true,
    canViewAttendance: true,
  );

  static const DashboardRolePolicy manager = DashboardRolePolicy(
    showExecutiveAdmin: true,
    showMemberHome: false,
    canManageMembers: true,
    canManageEvents: true,
    canManageInvitations: true,
    canViewAttendance: true,
  );

  static const DashboardRolePolicy member = DashboardRolePolicy(
    showExecutiveAdmin: false,
    showMemberHome: true,
    canManageMembers: false,
    canManageEvents: false,
    canManageInvitations: false,
    canViewAttendance: true,
  );
}
