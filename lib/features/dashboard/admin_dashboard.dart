import 'package:flutter/material.dart';

/// Dashboard Admin — Implementasi penuh: Week 12
///
/// Akan berisi:
/// - Kartu statistik (total event, total anggota, rata-rata kehadiran)
/// - Grafik persentase kehadiran
/// - Menu: Kelola Event, Scan QR, Rekap Kehadiran
/// - NetworkStatusBanner untuk indikator online/offline
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Admin — PRASASTI')),
      body: const Center(
        child: Text('Admin Dashboard — Implementasi: Week 12'),
      ),
    );
  }
}