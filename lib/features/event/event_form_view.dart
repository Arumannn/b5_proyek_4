import 'package:flutter/material.dart';

/// Form tambah/edit event — Implementasi penuh: Week 9
class EventFormView extends StatelessWidget {
  const EventFormView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Event')),
      body: const Center(
        child: Text('Event Form — Implementasi: Week 9'),
      ),
    );
  }
}