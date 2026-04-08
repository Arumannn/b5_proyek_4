import 'package:flutter/material.dart';

/// Layar tampilkan QR Code pribadi anggota — Implementasi penuh: Week 8
class QrDisplayView extends StatelessWidget {
  final String memberId;
  const QrDisplayView({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Saya')),
      body: const Center(
        child: Text('QR Display — Implementasi: Week 8'),
      ),
    );
  }
}