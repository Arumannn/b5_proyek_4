import 'package:flutter/material.dart';

/// Layar daftar event (Admin) — Implementasi penuh: Week 9
class EventListView extends StatelessWidget {
  const EventListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Event')),
      body: const Center(
        child: Text('Event List — Implementasi: Week 9'),
      ),
    );
  }
}