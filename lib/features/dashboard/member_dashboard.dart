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

  static const String _dummyMemberId = 'MEMBER-PRASASTI-001';
  static const String _dummyNama = 'Budi Santosoo';
  static const String _dummyNim = '2310112345';
  static const String _dummyDivisi = 'Pengembangan Aplikasi';

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'UI Testing Member',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gunakan tombol di bawah untuk test tampilan QR dan profil anggota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => QrDisplayView(
                      nim: _dummyMemberId,
                      qrData: QrService.generateQrData(_dummyMemberId),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_2),
              label: const Text('Test UI QR Code'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MemberProfileView(
                      nama: _dummyNama,
                      nim: _dummyNim,
                      divisi: _dummyDivisi,
                      memberId: _dummyMemberId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.account_circle),
              label: const Text('Test UI Member Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
