import 'package:flutter/material.dart';

class InvitationSummaryCards extends StatelessWidget {
  final int totalAnggota;
  final int selectedCount;
  final int pendingCount;

  const InvitationSummaryCards({
    super.key,
    required this.totalAnggota,
    required this.selectedCount,
    required this.pendingCount,
  });

  Widget _buildSummaryBox({
    required String label,
    required int count,
    required Color bgColor,
    required Color borderColor,
    required Color labelColor,
    required Color countColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSummaryBox(
          label: 'Total Anggota',
          count: totalAnggota,
          bgColor: const Color(0xFFEFF6FF),
          borderColor: const Color(0xFFDBEAFE),
          labelColor: const Color(0xFF2563EB),
          countColor: const Color(0xFF1E40AF),
        ),
        const SizedBox(width: 12),
        _buildSummaryBox(
          label: 'Terpilih',
          count: selectedCount,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFDCFCE7),
          labelColor: const Color(0xFF16A34A),
          countColor: const Color(0xFF166534),
        ),
        const SizedBox(width: 12),
        _buildSummaryBox(
          label: 'Menunggu',
          count: pendingCount,
          bgColor: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFFEDD5),
          labelColor: const Color(0xFFEA580C),
          countColor: const Color(0xFF9A3412),
        ),
      ],
    );
  }
}
