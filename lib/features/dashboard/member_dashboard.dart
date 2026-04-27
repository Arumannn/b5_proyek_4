import 'package:flutter/material.dart';
import '../../widgets/network_status_banner.dart';
import '../auth/auth_controller.dart';
import '../member/member_profile_view.dart';
import '../member/qr_display_view.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

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
          title: const Text('Dashboard Member — PRASASTI'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => _confirmAndLogout(context),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: AuthController.instance.currentUser,
          builder: (context, user, _) {
            final nama = user?.nama ?? 'Member';
            final nim = user?.nim ?? '-';
            final divisi = user?.divisi ?? '-';
            final memberId = user?.memberId ?? nim;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Profil Card Singkat ────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            child: Icon(
                              Icons.person_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'NIM: $nim · $divisi',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Aksi Utama ─────────────────────────────────
                  Text(
                    'Menu Saya',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),

                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => QrDisplayView(nim: memberId),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Tampilkan QR Code Saya'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => MemberProfileView(
                          nama: nama,
                          nim: nim,
                          divisi: divisi,
                          memberId: memberId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.account_circle_outlined),
                    label: const Text('Lihat Profil Saya'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}