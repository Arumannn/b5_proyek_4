import 'package:flutter/material.dart';

/// Riwayat kehadiran pribadi Member — Implementasi penuh: Week 12
class AttendanceHistoryView extends StatelessWidget {
  final String nim;
  const AttendanceHistoryView({super.key, required this.nim});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Kehadiran')),
      body: const Center(
        child: Text('Attendance History — Implementasi: Week 12'),
      ),
    );
  }
}