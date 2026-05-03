import 'package:flutter/material.dart';

import '../../widgets/gradient_header.dart';

/// Riwayat kehadiran pribadi Member — Implementasi penuh: Week 12
class AttendanceHistoryView extends StatelessWidget {
  final String nim;
  const AttendanceHistoryView({super.key, required this.nim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientHeader(title: 'Riwayat Kehadiran', subtitle: 'Riwayat absensi pribadi'),
      body: const Center(
        child: Text('Attendance History — Implementasi: Week 12'),
      ),
    );
  }
}