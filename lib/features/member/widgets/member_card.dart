import 'package:flutter/material.dart';
import '../../../models/member_model.dart';

/// Individual member card with info and action menu
class MemberCard extends StatelessWidget {
  final MemberModel member;
  final bool isExecutive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MemberCard({
    super.key,
    required this.member,
    required this.isExecutive,
    required this.onEdit,
    required this.onDelete,
  });

  String _getInitials() {
    if (member.nama.isEmpty) return '?';
    return member.nama[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = member.nama.split(' ').first.toLowerCase();
    final dummyEmail = '$firstName@email.com';
    final dummyPhone = '081234567890';
    final attendancePercent = 75 + (member.nama.length % 25);
    final isHighAttendance = attendancePercent >= 90;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info Utama
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.nama,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHighAttendance)
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.amber,
                              size: 24,
                            ),
                        ],
                      ),
                      Text(
                        'NIM: ${member.nim}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.person_outline,
                        '${member.divisi} - ${member.role}',
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.mail_outline, dummyEmail),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.phone_outlined, dummyPhone),
                    ],
                  ),
                ),

                // Titik Tiga (Menu Edit & Hapus)
                if (isExecutive)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit')
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('Hapus')
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Progress Kehadiran
            Row(
              children: [
                const Text(
                  'Tingkat Kehadiran: ',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: attendancePercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: isHighAttendance
                          ? Colors.green
                          : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$attendancePercent%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build info row with icon and text
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
