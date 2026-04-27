import 'package:flutter/material.dart';
import '../../widgets/network_status_banner.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../event/event_list_view.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AuthController.instance.logout(context);
    }
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final primaryColor = iconColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Icon(icon, color: primaryColor),
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
    // ── Wrap Scaffold dengan NetworkStatusBanner ──────────────────
    return NetworkStatusBanner(
      child: Scaffold(
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
              // ── Greeting ────────────────────────────────────────
              ValueListenableBuilder(
                valueListenable: AuthController.instance.currentUser,
                builder: (_, user, __) => Text(
                  'Selamat datang, ${user?.nama ?? 'Admin'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola absensi, event, dan anggota PRASASTI',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 16),

              // ── Menu Cards ───────────────────────────────────────
              _buildMenuCard(
                context: context,
                icon: Icons.event_note_outlined,
                title: 'Kelola Event',
                subtitle: 'Tambah, edit, hapus event dan sub event',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const EventListView()),
                ),
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scan Absensi',
                subtitle: 'Buka scanner QR untuk proses kehadiran',
                iconColor: Colors.green.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ScanScreen(eventId: 'manual-scan'),
                  ),
                ),
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.assignment_outlined,
                title: 'Rekap Kehadiran',
                subtitle: 'Lihat ringkasan kehadiran per event',
                iconColor: Colors.orange.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AttendanceRecapView(eventId: 'ev-001'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}