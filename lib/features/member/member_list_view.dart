import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import 'member_form_view.dart';
import 'member_controller.dart';
import '../../models/member_model.dart';

class MemberListView extends StatefulWidget {
  final bool showBottomNav;

  const MemberListView({super.key, this.showBottomNav = true});

  @override
  State<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView> {
  final MemberController _controller = MemberController.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isExecutive {
    final role = (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();
    return role == AppConstants.roleExecutive.toLowerCase() ||
        role == 'executive' ||
        role == 'eksekutif' ||
        role == 'admin';
  }

  Future<void> _editMember(MemberModel member) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UserFormDialog(
        authController: AuthController.instance,
        existing: member,
        roleLabelBuilder: _roleLabel,
        dbuItemsBuilder: _buildDbuItems,
      ),
    );

    if (saved == true) {
      await _loadMembers();
      if (!mounted) return;
      CustomSnackbar.showSuccess(context, 'Data anggota berhasil diperbarui.');
    }
  }

  Future<void> _addMember() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const MemberFormView(),
      ),
    );

    if (saved == true) {
      await _loadMembers();
      if (!mounted) return;
      CustomSnackbar.showSuccess(context, 'Anggota baru berhasil ditambahkan.');
    }
  }

  Future<void> _deleteMember(MemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Hapus anggota ${member.nama} (${member.nim})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await AuthController.instance.deleteUserByExecutive(member.nim);
    if (!mounted) return;

    if (!success) {
      CustomSnackbar.showError(
        context,
        AuthController.instance.errorMessage.value ?? 'Gagal menghapus anggota.',
      );
      return;
    }

    await _loadMembers();
    if (!mounted) return;
    CustomSnackbar.showSuccess(context, 'Anggota berhasil dihapus.');
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == 'executive' || normalized == 'eksekutif' || normalized == 'admin') {
      return 'Executive';
    }
    if (normalized == AppConstants.roleManager) return 'Manager';
    if (normalized == AppConstants.roleOrganizer) return 'Organizer';
    return 'Member';
  }

  List<DropdownMenuItem<String>> _buildDbuItems() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.black54,
    );

    return [
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_departemen__',
        child: Text('Departemen', style: headerStyle),
      ),
      ...AppConstants.departmentDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_biro__',
        child: Text('Biro', style: headerStyle),
      ),
      ...AppConstants.biroDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_unit__',
        child: Text('Unit', style: headerStyle),
      ),
      ...AppConstants.unitDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
    ];
  }

  Future<void> _loadMembers({bool syncFromCloud = true}) async {
    if (mounted) {
      _controller.loadMembers();
    }

    if (!syncFromCloud) return;
    if (!NetworkStatusController.instance.isOnline.value) return;

    try {
      final docs = await MongoService.instance.findMany(
        collectionName: AppConstants.usersCollection,
      );

      if (docs.isEmpty) return;

      bool updated = false;
      for (final raw in docs) {
        final map = Map<String, dynamic>.from(raw)..remove('_id');
        final member = MemberModel.fromMap(map);
        if (member.nim.isEmpty) continue;

        await HiveService.members.put(member.nim, member);
        updated = true;
      }

      if (updated) _controller.loadMembers();
    } catch (e) {
      debugPrint('[MemberList] Cloud sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
              ),
              child: ValueListenableBuilder<List<MemberModel>>(
                valueListenable: _controller.members,
                builder: (context, membersList, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Daftar Anggota',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isExecutive)
                            GestureDetector(
                              onTap: _addMember,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person_add_alt_1, size: 18, color: Color(0xFF2563EB)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Tambah',
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.groups_2_outlined, size: 44, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${membersList.length} anggota aktif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kelola anggota, role, dan data DBU dari satu tempat.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _buildSearchBarCard(),
            ),
            _buildFilterChips(),
            Expanded(
              child: _buildMemberList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) {
          return TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIM...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: const Color(0xFFF3F7FD),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _controller.availableDivisions,
        builder: (context, divisions, _) {
          return ValueListenableBuilder<String>(
            valueListenable: _controller.selectedDivision,
            builder: (context, selectedDiv, _) {
              return SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: divisions.length,
                  itemBuilder: (context, index) {
                    final div = divisions[index];
                    final isSelected = div == selectedDiv;
                    final count = _controller.getDivisionCount(div);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('$div ($count)'),
                        selected: isSelected,
                        onSelected: (_) => _controller.setDivision(div),
                        selectedColor: const Color(0xFFDBEAFE),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF1D4ED8) : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberList() {
    return RefreshIndicator(
      onRefresh: () => _loadMembers(syncFromCloud: true),
      child: ValueListenableBuilder<List<MemberModel>>(
        valueListenable: _controller.filteredMembers,
        builder: (context, filtered, child) {
          if (filtered.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(
                  child: Text('Tidak ada anggota yang cocok', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              ],
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final member = filtered[index];
              return _MemberCardDesign(
                member: member,
                isExecutive: _isExecutive,
                onEdit: () => _editMember(member),
                onDelete: () => _deleteMember(member),
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== MEMBER CARD ====================

class _MemberCardDesign extends StatelessWidget {
  final MemberModel member;
  final bool isExecutive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCardDesign({
    required this.member,
    required this.isExecutive,
    required this.onEdit,
    required this.onDelete,
  });

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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 18, offset: const Offset(0, 8))],
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
                    member.nama.isNotEmpty ? member.nama[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHighAttendance)
                            const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                        ],
                      ),
                      Text('NIM: ${member.nim}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person_outline, '${member.divisi} - ${member.role}'),
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
                        children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('Hapus')],
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
                const Text('Tingkat Kehadiran: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: attendancePercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: isHighAttendance ? Colors.green : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$attendancePercent%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

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