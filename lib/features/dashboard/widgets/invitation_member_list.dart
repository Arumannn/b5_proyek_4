import 'package:flutter/material.dart';

import '../../../models/member_model.dart';

class InvitationMemberList extends StatelessWidget {
  final List<MemberModel> filteredMembers;
  final Map<String, bool> selectedMembers;
  final String filterRole;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<String> onFilterRoleChanged;
  final VoidCallback onToggleAll;
  final void Function(String, bool) onToggleMember;

  const InvitationMemberList({
    super.key,
    required this.filteredMembers,
    required this.selectedMembers,
    required this.filterRole,
    required this.onSearchQueryChanged,
    required this.onFilterRoleChanged,
    required this.onToggleAll,
    required this.onToggleMember,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = filteredMembers.isNotEmpty &&
        filteredMembers.every((m) => selectedMembers[m.nim] == true);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAFTAR ANGGOTA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: onToggleAll,
                child: Text(
                  allSelected ? 'Batal Semua' : 'Pilih Semua',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: onSearchQueryChanged,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              decoration: const InputDecoration(
                hintText: 'Cari anggota...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 16, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Executive', 'Manager', 'Organizer', 'Member'].map((role) {
                final isSelected = filterRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onFilterRoleChanged(role),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            child: filteredMembers.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Tidak ada anggota yang sesuai.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredMembers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filteredMembers[index];
                      final isSelected = selectedMembers[user.nim] ?? false;

                      return InkWell(
                        onTap: () {
                          onToggleMember(user.nim, !isSelected);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF9FAFB) : Colors.white,
                            border: Border.all(color: Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (val) {
                                    if (val != null) {
                                      onToggleMember(user.nim, val);
                                    }
                                  },
                                  activeColor: const Color(0xFF2563EB),
                                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nama,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${user.role} • ${user.nim}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
