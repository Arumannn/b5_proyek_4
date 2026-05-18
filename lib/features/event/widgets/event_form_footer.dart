import 'package:flutter/material.dart';

class EventFormFooter extends StatelessWidget {
  final VoidCallback onSubmit;

  const EventFormFooter({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[100]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info, color: Colors.blue[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.blue[800], height: 1.5),
                    children: const [
                      TextSpan(text: 'Karena sistem menggunakan konsep '),
                      TextSpan(text: 'Offline-First', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ', data event akan disimpan di memori lokal terlebih dahulu dan otomatis disinkronkan ke cloud saat koneksi tersedia.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.save, color: Colors.white, size: 20),
            label: const Text('Simpan Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: Colors.blue[200],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
