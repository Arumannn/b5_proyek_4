import 'package:flutter/material.dart';
import '../auth/auth_controller.dart';

/// Dashboard Organizer — placeholder.
class OrganizerDashboard extends StatelessWidget {
  const OrganizerDashboard({super.key});

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
      body: const Center(
        child: Text('Organizer Dashboard — Implementasi lanjutan'),
      ),
    );
  }
}
