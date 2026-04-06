class QrService {
  /// Generate data yang akan di-encode ke QR Code.
  /// Format: "PRASASTI:{memberId}"
  /// Prefix digunakan untuk validasi saat scan —
  /// QR yang tidak diawali prefix ini dianggap tidak valid.
  static String generateQrData(String memberId) {
    return 'PRASASTI:$memberId';
  }

  /// Parse QR Code yang di-scan.
  /// Return memberId jika valid, null jika format tidak dikenal.
  static String? parseMemberId(String qrData) {
    const prefix = 'PRASASTI:';
    if (!qrData.startsWith(prefix)) return null;

    final memberId = qrData.substring(prefix.length).trim();
    if (memberId.isEmpty) return null;

    return memberId;
  }

  /// Validasi apakah string adalah QR PRASASTI yang valid
  static bool isValidQr(String qrData) {
    return parseMemberId(qrData) != null;
  }
}