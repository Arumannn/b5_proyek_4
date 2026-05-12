import 'package:flutter/material.dart';
import '../../../models/member_model.dart';
import '../../member/qr_display_view.dart';

/// Kartu QR code kehadiran member dengan navigasi ke detail QR.
class MemberQrCard extends StatelessWidget {
  final MemberModel member;

  const MemberQrCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final nimIsEmpty = member.nim.trim().isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: nimIsEmpty
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => QrDisplayView(nim: member.nim),
                ),
              );
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'QR Code Kehadiran Anda',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.qr_code, size: 120, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            Text(
              member.nama,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'NIM: ${member.nim}',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ketuk untuk melihat QR code kehadiran',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
