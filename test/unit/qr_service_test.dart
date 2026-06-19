import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/domain/utils/qr_service.dart';

void main() {
  group('QrService', () {
    test('generateQrData menghasilkan prefix PRASASTI', () {
      const nim = '241511039';
      final qrData = QrService.generateQrData(nim);

      expect(qrData, equals('PRASASTI:241511039'));
    });

    test('parseNim mengembalikan nim untuk QR valid', () {
      final nim = QrService.parseNim('PRASASTI:241511040');

      expect(nim, equals('241511040'));
    });

    test('parseNim mengembalikan null untuk prefix tidak valid', () {
      final nim = QrService.parseNim('QRLAIN:241511040');

      expect(nim, isNull);
    });

    test('parseNim mengembalikan null untuk nim kosong', () {
      final nim = QrService.parseNim('PRASASTI:   ');

      expect(nim, isNull);
    });

    test('isValidQr true hanya untuk format PRASASTI dengan nim non-kosong', () {
      expect(QrService.isValidQr('PRASASTI:241511041'), isTrue);
      expect(QrService.isValidQr('PRASASTI:'), isFalse);
      expect(QrService.isValidQr('RANDOM'), isFalse);
    });
  });
}
