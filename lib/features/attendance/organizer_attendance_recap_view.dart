import 'package:flutter/material.dart';
import '../../core/auth/attendance_role_policy.dart';
import 'attendance_recap_shared_view.dart';

class OrganizerAttendanceRecapView extends StatelessWidget {
  const OrganizerAttendanceRecapView({super.key});
  @override
  Widget build(BuildContext context) {
    return const AttendanceRecapSharedView(
      title: 'Rekap Kehadiran (Read-Only)',
      policy: AttendanceRolePolicy.organizer,
    );
  }
}
