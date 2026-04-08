import 'package:flutter/material.dart';

/// Layar Scanner QR Code — Implementasi penuh: Week 9
class ScanScreen extends StatelessWidget {
  final String eventId;
  const ScanScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Absensi')),
      body: const Center(
        child: Text('QR Scanner — Implementasi: Week 9'),
      ),
    );
  }
}