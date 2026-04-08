import 'package:flutter/material.dart';

/// Layar Login — Implementasi penuh: Week 8
///
/// RULES yang akan diterapkan di Week 8:
/// - Gunakan ValueListenableBuilder untuk state loading/error
/// - ZERO setState untuk data dinamis
/// - Navigasi ke Admin/Member dashboard berdasarkan role
/// - Gunakan pushReplacement agar tidak bisa back ke login
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B3A6B),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Login Screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Implementasi: Week 8',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}