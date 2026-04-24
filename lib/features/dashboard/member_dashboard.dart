import 'package:flutter/material.dart';
import '../../core/utils/qr_service.dart';
import '../auth/auth_controller.dart';
import '../member/member_profile_view.dart';
import '../member/qr_display_view.dart';

/// Dashboard Member — Implementasi penuh: Week 12
///
/// Akan berisi:
/// - QR Code pribadi yang bisa di-zoom
/// - Riwayat kehadiran diri sendiri
/// - NetworkStatusBanner
class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

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
        title: const Text('Dashboard Member — PRASASTI'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder(
          valueListenable: AuthController.instance.currentUser,
          builder: (context, currentUser, _) {
            if (currentUser == null) {
              return const Center(
                child: Text('Data member belum tersedia. Silakan login ulang.'),
              );
            }

            final qrData = currentUser.qrCodeValue.isNotEmpty
                ? currentUser.qrCodeValue
                : QrService.generateQrData(currentUser.nim);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Halo, ${currentUser.nama}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gunakan QR ini saat absensi dan cek profil Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QrDisplayView(
                          nim: currentUser.nim,
                          qrData: qrData,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('Lihat QR Code Saya'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MemberProfileView(
                          nama: currentUser.nama,
                          nim: currentUser.nim,
                          divisi: currentUser.divisi,
                          memberId: currentUser.memberId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Lihat Profil Saya'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
