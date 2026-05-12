import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/white_status_header.dart';
import '../../widgets/sectioned_list_body.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import 'member_form_view.dart';
import 'member_controller.dart';
import '../../models/member_model.dart';
import 'widgets/member_card.dart';
import 'widgets/member_search_bar.dart';
import 'widgets/member_role_filter.dart';

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
      appBar: WhiteStatusHeader(
        title: 'Daftar Anggota',
        subtitle: 'Total 156 anggota aktif',
        statusBadge: ValueListenableBuilder<bool>(
          valueListenable: NetworkStatusController.instance.isOnline,
          builder: (context, isOnline, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFE8F7EF) : const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 10,
                    color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isOnline ? 'TERSINKRONISASI' : 'OFFLINE (SIMPAN LOKAL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: _isExecutive
            ? [
                IconButton(
                  tooltip: 'Tambah Anggota',
                  onPressed: _addMember,
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF111827)),
                ),
              ]
            : [],
      ),
      backgroundColor: const Color(0xFFF3F7FD),
      body: SafeArea(
        child: SectionedListBody(
          searchArea: _buildSearchBarCard(),
          filterArea: _buildFilterChips(),
          content: _buildMemberList(),
        ),
      ),
    );
  }

  Widget _buildSearchBarCard() {
    return MemberSearchBar(controller: _searchController);
  }

  Widget _buildFilterChips() {
    return MemberRoleFilter(controller: _controller);
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
              return MemberCard(
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
