import 'package:flutter/material.dart';
import '../event/event_list_view.dart';

/// Rekap kehadiran per event (Admin) — Implementasi penuh: Week 12
class AttendanceRecapView extends StatelessWidget {
  final String eventId;
  const AttendanceRecapView({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rekap Kehadiran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event terpilih: ${widget.eventId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Kelola daftar event dan sub event dilakukan dari halaman Daftar Event.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const EventListView(),
                  ),
                );
              },
              icon: const Icon(Icons.event_note_outlined),
              label: const Text('Buka Daftar Event'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Rekap Absensi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Expanded(
              child: Center(
                child: Text('Panel rekap absensi per event akan ditampilkan di sini.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
