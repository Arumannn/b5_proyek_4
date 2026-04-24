import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../event/event_list_view.dart';

/// Dashboard Admin — Implementasi penuh: Week 12
///
/// Akan berisi:
/// - Kartu statistik (total event, total anggota, rata-rata kehadiran)
/// - Grafik persentase kehadiran
/// - Menu: Kelola Event, Scan QR, Rekap Kehadiran
/// - NetworkStatusBanner untuk indikator online/offline
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _openScanForSelectedEvent(BuildContext context) async {
    final events = HiveService.events.values.toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada event. Silakan buat event terlebih dahulu.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<EventModel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Pilih Event untuk Scan'),
                subtitle: Text('QR anggota akan dicatat ke event ini.'),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.nama),
                      subtitle: Text(
                        '${event.jenis} • ${event.tanggal.toLocal()}',
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(event),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(eventId: selected.eventId),
      ),
    );
  }

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await AuthController.instance.logout(context);
    }
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin — PRASASTI'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Admin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context: context,
              icon: Icons.event_note_outlined,
              title: 'Kelola Event',
              subtitle: 'Tambah, edit, hapus event dan sub event',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const EventListView(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.qr_code_scanner_outlined,
              title: 'Scan Absensi',
              subtitle: 'Pilih event lalu scan QR anggota',
              onTap: () => _openScanForSelectedEvent(context),
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.assignment_outlined,
              title: 'Rekap Kehadiran',
              subtitle: 'Lihat ringkasan kehadiran per event',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AttendanceRecapView(eventId: 'ev-001'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}