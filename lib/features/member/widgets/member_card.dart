import 'package:flutter/material.dart';
import '../../../models/member_model.dart';
import '../../../core/constants/app_constants.dart';

/// Individual member card matching the minimal reference design
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
    final parts = member.nama.split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return member.nama.substring(0, member.nama.length > 1 ? 2 : 1).toUpperCase();
  }

  Color _getRoleBgColor(String role) {
    final r = role.toLowerCase();
    if (r == AppConstants.roleExecutive.toLowerCase()) {
      return const Color(0xFFF3E8FF); // bg-purple-100
    } else if (r == AppConstants.roleManager.toLowerCase()) {
      return const Color(0xFFDBEAFE); // bg-blue-100
    } else if (r == AppConstants.roleOrganizer.toLowerCase()) {
      return const Color(0xFFFFEDD5); // bg-orange-100
    }
    return const Color(0xFFF3F4F6); // bg-gray-100
  }

  Color _getRoleTextColor(String role) {
    final r = role.toLowerCase();
    if (r == AppConstants.roleExecutive.toLowerCase()) {
      return const Color(0xFF7E22CE); // text-purple-700
    } else if (r == AppConstants.roleManager.toLowerCase()) {
      return const Color(0xFF1D4ED8); // text-blue-700
    } else if (r == AppConstants.roleOrganizer.toLowerCase()) {
      return const Color(0xFFC2410C); // text-orange-700
    }
    return const Color(0xFF374151); // text-gray-700
  }

  String _getDisplayRole(String role) {
    final r = role.toLowerCase();
    if (r == AppConstants.roleExecutive.toLowerCase()) {
      return 'Eksekutif';
    } else if (r == AppConstants.roleManager.toLowerCase()) {
      return 'Manager';
    } else if (r == AppConstants.roleOrganizer.toLowerCase()) {
      return 'Organizer';
    }
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    final roleText = _getDisplayRole(member.role);

    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.grey.shade100), // border-gray-100
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                // Avatar (w-10 h-10)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, // bg-gray-100
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _getInitials(),
                    style: const TextStyle(
                      color: Color(0xFF4B5563), // text-gray-600
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // text-sm
                    ),
                  ),
                ),
                const SizedBox(width: 12), // space-x-3 equivalent
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        member.nama,
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937), // text-gray-800
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.nim,
                        style: const TextStyle(
                          fontSize: 12, // text-xs
                          color: Color(0xFF6B7280), // text-gray-500
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // px-2 py-1
                decoration: BoxDecoration(
                  color: _getRoleBgColor(member.role),
                  borderRadius: BorderRadius.circular(4), // rounded
                ),
                child: Text(
                  roleText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, // text-[10px]
                    fontWeight: FontWeight.bold,
                    color: _getRoleTextColor(member.role),
                    letterSpacing: 0.5, // tracking-wide
                  ),
                ),
              ),
              const SizedBox(height: 4), // mb-1 equivalent space
              if (isExecutive)
                InkWell(
                  onTap: () {
                    // Show a simple bottom sheet or popup for actions since the JS only shows one edit button but we have edit/delete
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit, color: Colors.blue),
                              title: const Text('Edit Anggota'),
                              onTap: () {
                                Navigator.pop(context);
                                onEdit();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Hapus Anggota', style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                onDelete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.edit_outlined, // Edit3 icon equivalent
                      size: 16,
                      color: Color(0xFF9CA3AF), // text-gray-400
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
