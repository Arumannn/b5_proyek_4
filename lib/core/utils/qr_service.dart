import '../constants/app_constants.dart';

/// Utility untuk generate dan parse data QR Code PRASASTI.
///
/// Format QR Code: "PRASASTI:{memberId}"
/// Prefix "PRASASTI:" digunakan untuk validasi saat scan —
/// QR dari aplikasi lain atau format tidak dikenal akan ditolak.
class QrService {
  QrService._(); // utility class, tidak perlu diinstansiasi

  /// Generate string data yang akan di-encode ke QR Code.
  /// Input: memberId (String UUID)
  /// Output: "PRASASTI:memberId"
  static String generateQrData(String memberId) {
    return '${AppConstants.qrPrefix}$memberId';
  }

  /// Parse QR Code yang di-scan.
  /// Return memberId jika format valid, null jika tidak valid.
  static String? parseMemberId(String qrData) {
    if (!qrData.startsWith(AppConstants.qrPrefix)) return null;
    final memberId = qrData.substring(AppConstants.qrPrefix.length).trim();
    if (memberId.isEmpty) return null;
    return memberId;
  }

  /// Validasi apakah string adalah QR Code PRASASTI yang valid.
  static bool isValidQr(String qrData) {
    return parseMemberId(qrData) != null;
  }
}