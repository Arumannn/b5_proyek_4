import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// Helper untuk menampilkan Snackbar dengan gaya konsisten di seluruh app.
///
/// Penggunaan:
/// ```dart
/// CustomSnackbar.showSuccess(context, 'Absensi berhasil dicatat!');
/// CustomSnackbar.showError(context, 'QR Code tidak dikenal.');
/// CustomSnackbar.showWarning(context, 'Data masih dalam antrian sync.');
/// ```
class CustomSnackbar {
  CustomSnackbar._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.green.shade700,
      icon: Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.red.shade700,
      icon: Icons.error_outline,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_outlined,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: Colors.blue.shade700,
      icon: Icons.info_outline,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    // Tutup snackbar yang sedang tampil sebelum menampilkan yang baru
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: AppConstants.snackbarDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}