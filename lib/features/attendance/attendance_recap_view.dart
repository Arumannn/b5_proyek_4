import 'package:flutter/material.dart';
import '../../core/auth/attendance_role_policy.dart';
import 'attendance_recap_shared_view.dart';

/// Rekap kehadiran per event (Admin) — Implementasi penuh: Week 12
class AttendanceRecapView extends StatelessWidget {
  final String? eventId;
  const AttendanceRecapView({super.key, this.eventId});
  @override
  Widget build(BuildContext context) {
    return AttendanceRecapSharedView(
      title: 'Rekap Kehadiran',
      policy: AttendanceRolePolicy.admin,
      initialEventId: eventId,
    );
  }
}
