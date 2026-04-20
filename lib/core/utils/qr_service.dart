import '../constants/app_constants.dart';

/// Utility untuk generate dan parse data QR Code PRASASTI.
///
/// Format QR Code: "PRASASTI:{nim}"
/// Prefix "PRASASTI:" digunakan untuk validasi saat scan —
/// QR dari aplikasi lain atau format tidak dikenal akan ditolak.
class QrService {
  QrService._(); // utility class, tidak perlu diinstansiasi

  /// Generate string data yang akan di-encode ke QR Code.
  /// Input: nim (String)
  /// Output: "PRASASTI:nim"
  static String generateQrData(String nim) {
    return '${AppConstants.qrPrefix}$nim';
  }

  /// Parse QR Code yang di-scan.
  /// Return nim jika format valid, null jika tidak valid.
  static String? parseNim(String qrData) {
    if (!qrData.startsWith(AppConstants.qrPrefix)) return null;
    final nim = qrData.substring(AppConstants.qrPrefix.length).trim();
    if (nim.isEmpty) return null;
    return nim;
  }

  /// Validasi apakah string adalah QR Code PRASASTI yang valid.
  static bool isValidQr(String qrData) {
    return parseNim(qrData) != null;
  }
}