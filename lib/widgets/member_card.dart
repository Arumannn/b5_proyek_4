import 'package:flutter/material.dart';

class MemberCard extends StatelessWidget {
  final String name;
  final String nim;
  final String division;
  final double attendancePercent;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.name,
    required this.nim,
    required this.division,
    this.attendancePercent = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: const Color(0xFF60A5FA), child: Text(name.isNotEmpty ? name[0] : '?')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('NIM: $nim • $division', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (attendancePercent.clamp(0, 100)) / 100.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
