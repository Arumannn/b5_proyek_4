import 'package:flutter/material.dart';
import 'package:b5_proyek_4/data/services/sync_manager.dart';
import 'package:b5_proyek_4/domain/controllers/network_status_controller.dart';

/// Banner status jaringan + sync yang muncul di semua layar utama.
///
/// - OFFLINE  → banner merah, teks "offline — data tersimpan lokal"
/// - ONLINE + pending sync → banner biru, teks "menyinkronkan..."
/// - ONLINE + syncing done → banner hilang smooth
///
/// Cara pakai:
/// ```dart
/// return NetworkStatusBanner(child: Scaffold(...));
/// ```
class NetworkStatusBanner extends StatelessWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BannerLayer(),
        Expanded(child: child),
      ],
    );
  }
}

/// Layer banner terpisah agar rebuild tidak mempengaruhi child.
class _BannerLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkStatusController.instance.isOnline,
      builder: (context, isOnline, _) {
        if (!isOnline) {
          // ── OFFLINE Banner ────────────────────────────────────────
          return _AnimatedBanner(
            visible: true,
            color: Colors.red.shade700,
            icon: Icons.wifi_off_rounded,
            message: 'OFFLINE — Data tersimpan lokal, sync otomatis saat online',
          );
        }

        // ── ONLINE: tampilkan status sync jika ada pending ─────────
        return ValueListenableBuilder<bool>(
          valueListenable: SyncManager.instance.isSyncing,
          builder: (context, isSyncing, _) {
            if (isSyncing) {
              return _AnimatedBanner(
                visible: true,
                color: Colors.blue.shade700,
                icon: Icons.sync_rounded,
                message: 'Menyinkronkan data ke cloud...',
                showSpinner: true,
              );
            }

            return ValueListenableBuilder<int>(
              valueListenable: SyncManager.instance.pendingCount,
              builder: (context, pending, _) {
                if (pending > 0) {
                  return _AnimatedBanner(
                    visible: true,
                    color: Colors.orange.shade700,
                    icon: Icons.cloud_upload_outlined,
                    message: '$pending data menunggu sinkronisasi',
                  );
                }

                // Online, tidak ada pending → banner hilang
                return const _AnimatedBanner(visible: false);
              },
            );
          },
        );
      },
    );
  }
}

/// Widget banner dengan animasi smooth height.
class _AnimatedBanner extends StatelessWidget {
  final bool visible;
  final Color? color;
  final IconData? icon;
  final String? message;
  final bool showSpinner;

  const _AnimatedBanner({
    required this.visible,
    this.color,
    this.icon,
    this.message,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      height: visible ? 36 : 0,
      color: color ?? Colors.transparent,
      child: visible
          ? SingleChildScrollView(
              // Cegah overflow saat animasi menyusut
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showSpinner)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else if (icon != null)
                      Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}