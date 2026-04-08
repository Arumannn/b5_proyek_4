import 'package:flutter/material.dart';

/// Rekap kehadiran per event (Admin) — Implementasi penuh: Week 12
class AttendanceRecapView extends StatelessWidget {
  final String eventId;
  const AttendanceRecapView({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kehadiran')),
      body: const Center(
        child: Text('Attendance Recap — Implementasi: Week 12'),
      ),
    );
  }
}