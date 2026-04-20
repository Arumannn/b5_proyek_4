import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplayView extends StatelessWidget {
  final String memberId;

  const QrDisplayView({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Saya'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tunjukkan QR Code ini kepada Admin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Implementasi InteractiveViewer agar QR bisa di-zoom 
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: QrImageView(
                      data: memberId,
                      version: QrVersions.auto,
                      size: 300.0,
                      gapless: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ID: $memberId',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}