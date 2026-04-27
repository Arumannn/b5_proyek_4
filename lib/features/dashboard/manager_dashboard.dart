import 'package:flutter/material.dart';
import '../../widgets/network_status_banner.dart';
import '../auth/auth_controller.dart';
import '../event/event_list_view.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

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

  @override
  Widget build(BuildContext context) {
    return NetworkStatusBanner(
      child: Scaffold(
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
              ValueListenableBuilder(
                valueListenable: AuthController.instance.currentUser,
                builder: (_, user, __) => Text(
                  'Selamat datang, ${user?.nama ?? 'Manager'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const EventListView()),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          child: Icon(
                            Icons.event_note_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lihat Daftar Event',
                                  style: Theme.of(context).textTheme.titleMedium),
                              Text('Monitor event dan kehadiran',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Fitur lengkap Manager — Implementasi Week 12',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
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