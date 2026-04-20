import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MemberProfileView extends StatelessWidget {
  final String nama;
  final String nim;
  final String divisi;
  final String memberId;

  const MemberProfileView({
    super.key,
    required this.nama,
    required this.nim,
    required this.divisi,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Anggota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      child: Icon(Icons.person, size: 50),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      nama,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      nim,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Divider(height: 30),
                    _buildInfoRow(Icons.group, 'Divisi', divisi),
                    _buildInfoRow(Icons.badge, 'Role', 'Member'), // Default Role
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Section QR Code untuk Screenshot
            const Text(
              'Identitas Digital (QR Code)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: memberId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Simpan QR ini untuk absensi luring',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 15),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}