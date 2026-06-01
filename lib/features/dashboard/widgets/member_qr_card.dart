import 'package:flutter/material.dart';
import '../../../models/member_model.dart';
import '../../attendance/qr_display_view.dart';

class MemberQrCard extends StatelessWidget {
  final MemberModel member;

  const MemberQrCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final nimIsEmpty = member.nim.trim().isEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: nimIsEmpty
          ? null
          : () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => QrDisplayView(nim: member.nim))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('QR Code Kehadiran Anda', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2), 
              ),
              child: const Icon(Icons.qr_code_2, size: 140, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 16),
            Text(member.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(999)),
              child: Text('NIM: ${member.nim}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}