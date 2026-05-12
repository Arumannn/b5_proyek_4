import 'package:flutter/material.dart';

import '../../../core/auth/dashboard_role_policy.dart';
import '../../../models/member_model.dart';
import '../../event/event_controller.dart';
import 'member_dashboard_section.dart';
import 'executive_dashboard_section.dart';

/// Unified dashboard content yang adaptive berdasarkan policy role.
/// Tidak ada branching di page level, semua visibility ditentukan oleh policy.
class DashboardContent extends StatelessWidget {
  final MemberModel currentUser;
  final DashboardRolePolicy policy;
  final EventController eventController;

  const DashboardContent({
    super.key,
    required this.currentUser,
    required this.policy,
    required this.eventController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Admin/Executive Dashboard
        if (policy.showExecutiveAdmin) ...[
          const ExecutiveDashboardSection(),
        ],

        // Member Home Dashboard
        if (policy.showMemberHome) ...[
          MemberDashboardSection(
            eventController: eventController,
            currentUser: currentUser,
          ),
        ],
      ],
    );
  }
}
