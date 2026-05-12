import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/white_status_header.dart';
import '../auth/auth_controller.dart';
import 'member_form_view.dart';
import 'member_controller.dart';
import '../../models/member_model.dart';
import 'widgets/member_card.dart';

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
    return role == AppConstants.roleExecutive.toLowerCase();
  }

  Future<void> _editMember(MemberModel member) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MemberFormView(existing: member),
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
        subtitle: 'Total ${_controller.members.value.length} anggota aktif',
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
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // px-4 py-3
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200), // border-b border-gray-200
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6), // bg-gray-100
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: Color(0xFF1F2937), // text-gray-800
                    fontSize: 14, // text-sm
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Cari nama, NIM, atau peran...',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)), // text-gray-400
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), // py-2.5
                  ),
                ),
              ),
            ),
            
            // List Area
            Expanded(
              child: RefreshIndicator(
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
                            child: Text(
                              'Tidak ada anggota yang ditemukan.',
                              style: TextStyle(
                                color: Color(0xFF6B7280), // text-gray-500
                                fontSize: 14, // text-sm
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16), // p-4
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12), // space-y-3 equivalent
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
              ),
            ),
            if (widget.showBottomNav) const SizedBox(height: 80), // pb-20 equivalent for bottom padding if needed
          ],
        ),
      ),
    );
  }
}
