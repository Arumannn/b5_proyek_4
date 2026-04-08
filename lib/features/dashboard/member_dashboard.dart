import 'package:flutter/material.dart';

/// Dashboard Member — Implementasi penuh: Week 12
///
/// Akan berisi:
/// - QR Code pribadi yang bisa di-zoom
/// - Riwayat kehadiran diri sendiri
/// - NetworkStatusBanner
class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Member — PRASASTI')),
      body: const Center(
        child: Text('Member Dashboard — Implementasi: Week 12'),
      ),
    );
  }
}
