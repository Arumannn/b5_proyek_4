import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/utils/qr_service.dart';
import '../../widgets/white_status_header.dart';
import 'attendance_controller.dart';

class ScanScreen extends StatefulWidget {
  final String eventId;

  const ScanScreen({super.key, required this.eventId});

  // Meskipun dilarang  setState untuk logika bisnis, StatefulWidget
  // tetap wajib digunakan di sini HANYA untuk me-manage memori kamera (dispose).
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class ScanSuccessPayload {
  final String eventId;
  final String nama;
  final String identifier;
  final String status;

  const ScanSuccessPayload({
    required this.eventId,
    required this.nama,
    required this.identifier,
    required this.status,
  });
}

class _ScanScreenState extends State<ScanScreen> {
  // Inisialisasi controller scanner
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed:
        DetectionSpeed.noDuplicates, // Mencegah scan ganda bawaan library
    facing: CameraFacing.back,
  );

  // ValueNotifier untuk mengunci scanner agar tidak spam hit ke lokal/cloud
  final ValueNotifier<bool> _isProcessing = ValueNotifier<bool>(false);
  bool _isClosingAfterSuccess = false;

  @override
  void initState() {
    super.initState();
    AttendanceController.instance.preloadMembersFromCloudToHive();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _isProcessing.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing.value || _isClosingAfterSuccess) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null) {
      _showSnackbar('Format QR Tidak Terbaca', Colors.red);
      return;
    }

    _isProcessing.value = true;
    var shouldAutoClose = false;
    String? successStatus;

    try {
      final result = await AttendanceController.instance.recordAttendance(
        eventId: widget.eventId,
        scannedQrValue: qrData,
      );
      // Mengambil nama member untuk ditampilkan di Snackbar
      final namaMember =
          AttendanceController.instance.lastScannedName.value ?? 'Anggota';

      switch (result) {
        case AttendanceResult.successHadir:
          _showSnackbar('✅ Hadir: $namaMember', Colors.green);
          shouldAutoClose = true;
          successStatus = 'Hadir';
          break;
        case AttendanceResult.successTerlambat:
          _showSnackbar('⚠️ Terlambat: $namaMember', Colors.orange.shade700);
          shouldAutoClose = true;
          successStatus = 'Terlambat';
          break;
        case AttendanceResult.duplicate:
          _showSnackbar('❌ Ditolak: $namaMember SUDAH ABSEN!', Colors.red);
          break;
        case AttendanceResult.memberNotFound:
          final reason = AttendanceController.instance.lastFailureReason.value;
          _showSnackbar(
            reason == null || reason.isEmpty
                ? '❓ QR Tidak Valid / Bukan Anggota'
                : '❓ QR Tidak Valid / Bukan Anggota\n$reason',
            Colors.red.shade900,
          );
          break;
        case AttendanceResult.eventNotFound:
          _showSnackbar('Error: Data Event Hilang', Colors.grey);
          break;
        case AttendanceResult.mainEventHasSubEvents:
          _showSnackbar(
            'Main event ini memiliki sub-event. Scan absensi di sub-event.',
            Colors.orange.shade800,
          );
          break;
        case AttendanceResult.error:
          _showSnackbar(
            'Terjadi kesalahan sistem saat menyimpan data',
            Colors.red,
          );
          break;
      }
    } catch (e) {
      _showSnackbar('Exception: $e', Colors.red);
    } finally {
      if (shouldAutoClose) {
        _isClosingAfterSuccess = true;
        try {
          await _scannerController.stop();
        } catch (_) {
          // Abaikan error stop kamera agar flow kembali tetap lanjut.
        }

        if (mounted) {
          final identifier = QrService.parseNim(qrData) ?? qrData.trim();
          Navigator.of(context).pop(
            ScanSuccessPayload(
              eventId: widget.eventId,
              nama:
                  AttendanceController.instance.lastScannedName.value ??
                  'Anggota',
              identifier: identifier,
              status: successStatus ?? 'Hadir',
            ),
          );
        }
      } else {
        // 4. Beri jeda 2 detik agar Executive bisa melihat hasil Snackbar
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _isProcessing.value = false;
        }
      }
    }
  }

  // Fungsi pembantu untuk Snackbar (Bisa diganti dengan custom_snackbar.dart buatanmu)
  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 12),
            Text(
              'Scan Absensi',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: Color(0xFF111827)),
            tooltip: 'Nyalakan/Matikan Senter',
            onPressed: () {
              try {
                _scannerController.toggleTorch();
              } catch (e) {
                debugPrint('Gagal menyalakan senter: $e');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Layer 1: Kamera Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleDetect,
          ),

          // Layer 2: Overlay UI (Kotak pembidik & Efek Gelap)
          QRScannerOverlay(),

          // Layer 3: Indikator Loading saat memproses data
          ValueListenableBuilder<bool>(
            valueListenable: _isProcessing,
            builder: (context, isProcessing, child) {
              if (!isProcessing) return const SizedBox.shrink();
              return Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator()),
              );
            },
          ),

          // Teks Petunjuk di bawah
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isProcessing,
              builder: (context, isProcessing, child) {
                return Text(
                  isProcessing
                      ? 'Memproses data absensi...'
                      : 'Arahkan QR Code Anggota ke dalam kotak',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget tambahan untuk membuat efek visual kotak pembidik scanner
class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize:
              MediaQuery.of(context).size.width * 0.7, // Lebar area scan
        ),
      ),
    );
  }
}

/// Helper Class untuk memotong area hitam tengah (Overlay)
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final borderLengthValue = borderLength > cutOutSize / 2 + borderWidthSize
        ? cutOutSize / 2 + borderOffset
        : borderLength;
    final cutOutSizeValue = cutOutSize < width ? cutOutSize : width;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutSizeValue / 2 + borderOffset,
      rect.top + height / 2 - cutOutSizeValue / 2 + borderOffset,
      cutOutSizeValue - borderOffset * 2,
      cutOutSizeValue - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();

    // Draw borders
    canvas
      // Top left
      ..drawLine(
        cutOutRect.topLeft,
        Offset(cutOutRect.left + borderLengthValue, cutOutRect.top),
        borderPaint,
      )
      ..drawLine(
        cutOutRect.topLeft,
        Offset(cutOutRect.left, cutOutRect.top + borderLengthValue),
        borderPaint,
      )
      // Top right
      ..drawLine(
        cutOutRect.topRight,
        Offset(cutOutRect.right - borderLengthValue, cutOutRect.top),
        borderPaint,
      )
      ..drawLine(
        cutOutRect.topRight,
        Offset(cutOutRect.right, cutOutRect.top + borderLengthValue),
        borderPaint,
      )
      // Bottom left
      ..drawLine(
        cutOutRect.bottomLeft,
        Offset(cutOutRect.left + borderLengthValue, cutOutRect.bottom),
        borderPaint,
      )
      ..drawLine(
        cutOutRect.bottomLeft,
        Offset(cutOutRect.left, cutOutRect.bottom - borderLengthValue),
        borderPaint,
      )
      // Bottom right
      ..drawLine(
        cutOutRect.bottomRight,
        Offset(cutOutRect.right - borderLengthValue, cutOutRect.bottom),
        borderPaint,
      )
      ..drawLine(
        cutOutRect.bottomRight,
        Offset(cutOutRect.right, cutOutRect.bottom - borderLengthValue),
        borderPaint,
      );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
