import 'package:flutter/material.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/member_model.dart';
import '../../../widgets/empty_state_widget.dart';
import 'role_color_utility.dart';

/// Individual member card in selection list
class MemberSelectionCard extends StatelessWidget {
  final MemberModel member;
  final bool isSelected;
  final VoidCallback onToggle;

  const MemberSelectionCard({
    super.key,
    required this.member,
    required this.isSelected,
    required this.onToggle,
  });

  String _getInitials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(member.nama);
    final avatarColor = RoleColorUtility.getAvatarColor(member.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFDBEAFE).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.grey.shade100,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Modern Checkbox
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Avatar with gradient blue
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    avatarColor,
                    avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: avatarColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name and ID
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'NIM: ${member.nim}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Role Badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RoleColorUtility.getRoleBadgeColor(member.role),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.role,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RoleColorUtility.getRoleTextColor(member.role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Member selection list with role filtering
class MemberSelectionList extends StatelessWidget {
  final String roleFilter;
  final Map<String, bool> selectedMembers;
  final Function(String nim, bool value) onMemberToggle;

  const MemberSelectionList({
    super.key,
    required this.roleFilter,
    required this.selectedMembers,
    required this.onMemberToggle,
  });

  @override
  Widget build(BuildContext context) {
    final members = HiveService.members.values.where((m) {
      if (roleFilter == 'Semua') return true;
      return m.role.toLowerCase() == roleFilter.toLowerCase();
    }).toList();

    if (members.isEmpty) {
      return const SizedBox(
        height: 200,
        child: EmptyStateWidget(
          icon: Icons.people,
          title: 'Belum ada anggota',
          subtitle: 'Tambah anggota atau ubah filter.',
        ),
      );
    }

    return Column(
      children: members.map((member) {
        final isSelected = selectedMembers[member.nim] ?? false;
        return MemberSelectionCard(
          member: member,
          isSelected: isSelected,
          onToggle: () => onMemberToggle(member.nim, !isSelected),
        );
      }).toList(growable: false),
    );
  }
}
