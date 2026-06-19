import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:b5_proyek_4/domain/utils/qr_service.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/white_status_header.dart';

class QrDisplayView extends StatelessWidget {
  final String nim;
  const QrDisplayView({super.key, required this.nim});

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
            Icon(Icons.qr_code, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 12),
            Text(
              'QR Code Saya',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tunjukkan QR Code ini kepada Executive',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: QrImageView(
                          data: QrService.generateQrData(nim),
                          version: QrVersions.auto,
                          size: 280,
                          gapless: false,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ID: $nim',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}