import 'package:flutter/material.dart';

/// Individual statistic card
class StatisticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color accentColor;

  const StatisticCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Statistics section with overlapping effect
class InvitationStatsSection extends StatelessWidget {
  final int totalMembers;
  final int selectedCount;
  final int pendingInvites;

  const InvitationStatsSection({
    super.key,
    required this.totalMembers,
    required this.selectedCount,
    required this.pendingInvites,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Total Anggota
          Expanded(
            child: Transform.translate(
              offset: Offset.zero,
              child: StatisticCard(
                label: 'Total Anggota',
                value: '$totalMembers',
                icon: Icons.people,
                backgroundColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                accentColor: const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Terpilih
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, 12),
              child: StatisticCard(
                label: 'Terpilih',
                value: '$selectedCount',
                icon: Icons.check_circle,
                backgroundColor: const Color(0xFFFDE68A),
                iconColor: const Color(0xFFF59E0B),
                accentColor: const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Menunggu
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, 24),
              child: StatisticCard(
                label: 'Menunggu',
                value: '$pendingInvites',
                icon: Icons.mail_outline,
                backgroundColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                accentColor: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
