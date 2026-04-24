import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';
import '../manager/manager_attendance_management_view.dart';
import '../manager/manager_sub_event_management_view.dart';
import '../manager/manager_user_readonly_view.dart';

/// Dashboard Manager dengan kombinasi akses read-only + CRUD terpilih.
class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

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
        title: const Text('Dashboard Manager — PRASASTI'),
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
              'Akses Manager',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildMenuCard(
              context: context,
              icon: Icons.people_outline,
              title: 'Data Akun Pengguna',
              subtitle: 'Read-only NIM, Nama, Role, dan DBU',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ManagerUserReadonlyView(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.account_tree_outlined,
              title: 'Kelola Sub-Event',
              subtitle: 'Full CRUD sub-event dengan relasi event utama',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ManagerSubEventManagementView(),
                  ),
                );
              },
            ),
            _buildMenuCard(
              context: context,
              icon: Icons.assignment_turned_in_outlined,
              title: 'Kelola Rekap Kehadiran',
              subtitle: 'Lihat, tambah, edit, hapus kehadiran + scan QR',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ManagerAttendanceManagementView(),
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
