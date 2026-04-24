import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import '../organizer/organizer_attendance_recap_view.dart';
import '../organizer/organizer_event_overview_view.dart';
import '../organizer/organizer_qr_view.dart';

/// Dashboard Organizer dengan akses read-only event/rekap
/// dan QR pribadi untuk absensi sebagai peserta.
class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Organizer — PRASASTI'),
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
              'Akses Organizer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context: context,
              icon: Icons.event_note_outlined,
              title: 'Lihat Event Utama & Sub-Event',
              subtitle: 'Read-only daftar event dan detail tanpa CRUD',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const OrganizerEventOverviewView(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.assignment_outlined,
              title: 'Rekap Kehadiran',
              subtitle: 'Tabel NIM, Nama, Status Kehadiran, Timestamp',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const OrganizerAttendanceRecapView(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.qr_code_2,
              title: 'QR Absensi Saya',
              subtitle: 'QR unik organizer + status Sudah/Belum Absen',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const OrganizerQrView(),
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
