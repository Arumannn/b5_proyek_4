import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Member — PRASASTI')),
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
                    builder: (_) => const QrDisplayView(
                      memberId: _dummyMemberId,
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
