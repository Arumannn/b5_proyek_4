import 'package:flutter/material.dart';
import '../core/utils/network_status_controller.dart';

/// Banner yang muncul otomatis di atas layar saat offline.
///
/// Cara pakai — wrap Scaffold dengan widget ini:
/// ```dart
/// NetworkStatusBanner(child: Scaffold(...))
/// ```
///
/// Menggunakan ValueListenableBuilder — ZERO setState.
class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatusController.instance.isOnline,
      builder: (context, isOnline, _) {
        return Column(
          children: [
            // Banner muncul/hilang dengan animasi smooth
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              height: isOnline ? 0 : 36,
              color: Colors.red.shade700,
              child: isOnline
                  ? const SizedBox.shrink()
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'OFFLINE — Data tersimpan lokal, sync otomatis saat online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}