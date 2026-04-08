import 'package:flutter/material.dart';

/// Layar Register — Implementasi penuh: Week 8
class RegisterView extends StatelessWidget {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: const Center(
        child: Text('Register Screen — Implementasi: Week 8'),
      ),
    );
  }
}