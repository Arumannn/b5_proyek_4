import 'package:flutter_test/flutter_test.dart';
// Path diperbarui: QrService sudah dipindah ke core/utils/
import 'package:b5_proyek_4/core/utils/qr_service.dart';

void main() {
  group('QrService — Week 7 Basic Validation', () {
    test('generateQrData menghasilkan format PRASASTI yang benar', () {
      const memberId = 'member-123';
      final result = QrService.generateQrData(memberId);
      expect(result, equals('PRASASTI:member-123'));
    });

    test('parseMemberId berhasil extract ID dari QR valid', () {
      const qrData = 'PRASASTI:member-abc';
      final result = QrService.parseMemberId(qrData);
      expect(result, equals('member-abc'));
    });

    test('parseMemberId return null untuk format QR tidak valid', () {
      const qrData = 'INVALID:something';
      final result = QrService.parseMemberId(qrData);
      expect(result, isNull);
    });

    test('parseMemberId return null untuk empty memberId', () {
      const qrData = 'PRASASTI:';
      final result = QrService.parseMemberId(qrData);
      expect(result, isNull);
    });

    test('isValidQr return true untuk QR PRASASTI yang valid', () {
      expect(QrService.isValidQr('PRASASTI:abc123'), isTrue);
    });

    test('isValidQr return false untuk QR asing', () {
      expect(QrService.isValidQr('random_qr_data'), isFalse);
    });

    test('isValidQr return false untuk string kosong', () {
      expect(QrService.isValidQr(''), isFalse);
    });
  });
}