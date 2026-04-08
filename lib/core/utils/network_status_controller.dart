import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Controller untuk memantau status jaringan secara real-time.
///
/// Expose state via ValueNotifier agar View bisa bereaksi tanpa setState.
/// Digunakan oleh:
///   - NetworkStatusBanner widget (tampil saat offline)
///   - SyncManager (trigger sync saat kembali online) — Week 11
class NetworkStatusController {
  // ─── Singleton ─────────────────────────────────────
  static final NetworkStatusController instance =
      NetworkStatusController._internal();
  NetworkStatusController._internal();

  /// true = ada koneksi internet, false = offline
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  bool _isListening = false;

  /// Mulai memantau status jaringan.
  /// Panggil di main() setelah semua inisialisasi selesai.
  Future<void> startListening() async {
    if (_isListening) return;

    // 1. Cek status awal saat app pertama kali dibuka
    final initialResults = await Connectivity().checkConnectivity();
    isOnline.value = initialResults.any(
      (r) => r != ConnectivityResult.none,
    );
    debugPrint(
      '🌐 Network status awal: ${isOnline.value ? "ONLINE" : "OFFLINE"}',
    );

    // 2. Listen perubahan status secara real-time
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final online = results.any((r) => r != ConnectivityResult.none);

      // Hanya update & log jika status benar-benar berubah
      if (online != isOnline.value) {
        isOnline.value = online;
        debugPrint('🌐 Network status berubah: ${online ? "ONLINE" : "OFFLINE"}');

        // TODO Week 11: Trigger SyncManager saat kembali online
        // if (online) SyncManager.instance.syncPendingRecords();
      }
    });

    _isListening = true;
    debugPrint('✅ NetworkStatusController started');
  }
}