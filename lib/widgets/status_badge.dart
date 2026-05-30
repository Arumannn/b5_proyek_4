import 'package:flutter/material.dart';
import '../core/enums/status_enums.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  Color _getStatusColor(String s) {
    final lower = s.toLowerCase();
    
    if (lower == InvitationStatus.approved.value ||
        lower == InvitationStatus.autoApproved.value ||
        lower == AttendanceStatus.hadir.value.toLowerCase() ||
        lower == 'akan hadir') {
      return Colors.green;
    }
    
    if (lower == InvitationStatus.rejected.value ||
        lower == AttendanceStatus.ditolak.value.toLowerCase() ||
        lower == 'menolak hadir') {
      return Colors.red;
    }
    
    if (lower == InvitationStatus.permissionRequested.value ||
        lower == AttendanceStatus.izin.value.toLowerCase() ||
        lower == AttendanceStatus.sakit.value.toLowerCase() ||
        lower == AttendanceStatus.terlambat.value.toLowerCase() ||
        lower.contains('izin')) {
      return Colors.orange;
    }
    
    return Colors.grey.shade600;
  }

  String _getDisplayStatus(String s) {
    final lower = s.toLowerCase();
    if (lower == InvitationStatus.approved.value || lower == InvitationStatus.autoApproved.value) {
      return 'Hadir';
    }
    if (lower == InvitationStatus.rejected.value) {
      return 'Ditolak';
    }
    if (lower == InvitationStatus.permissionRequested.value) {
      return 'Izin';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final displayStatus = _getDisplayStatus(status);
    final color = _getStatusColor(status);
    final bgColor = color.withValues(alpha: 0.12);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
