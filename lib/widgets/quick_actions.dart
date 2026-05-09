import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onFillAttendance;
  final VoidCallback? onReports;
  const QuickActions({super.key, this.onFillAttendance, this.onReports});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onFillAttendance,
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Isi Absensi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReports,
            icon: const Icon(Icons.insert_drive_file),
            label: const Text('Laporan'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
