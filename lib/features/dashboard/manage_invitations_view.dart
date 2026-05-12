import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../models/event_invitation.dart';
import '../auth/auth_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/sectioned_list_body.dart';
import 'widgets/invitation_header.dart';
import 'widgets/invitation_stats_section.dart';
import 'widgets/member_selection_list.dart';
import 'widgets/invitation_action_bar.dart';

class ManageInvitationsView extends StatefulWidget {
  const ManageInvitationsView({super.key});

  @override
  State<ManageInvitationsView> createState() => _ManageInvitationsViewState();
}

class _ManageInvitationsViewState extends State<ManageInvitationsView> {
  List<EventModel> _events = [];
  Map<String, bool> _selectedMembers = {};
  String? _selectedEventId;
  bool _isLoading = true;
  final ValueNotifier<String> _selectedRoleFilter = ValueNotifier<String>('Semua');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _selectedRoleFilter.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final events = HiveService.events.values.toList();
      final members = HiveService.members.values.toList();

      setState(() {
        _events = events;
        _selectedMembers = {for (final m in members) m.nim: false};
        if (_events.isNotEmpty && _selectedEventId == null) {
          _selectedEventId = _events.first.eventId;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackbar.showError(context, 'Gagal memuat data: $e');
    }
  }

  Future<void> _sendInvitations() async {
    if (_selectedEventId == null) return;

    final selected = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selected.isEmpty) {
      CustomSnackbar.showError(
        context,
        'Pilih minimal satu anggota untuk dikirimi undangan.',
      );
      return;
    }

    try {
      final currentUser = AuthController.instance.currentUser.value;
      final invitedBy = currentUser?.nim ?? 'system';
      final event = HiveService.events.get(_selectedEventId);
      final attendanceTime = event?.tanggalMulai ?? DateTime.now();

      for (final nim in selected) {
        final invitationId = 'INV-${DateTime.now().millisecondsSinceEpoch}-$nim';
        final invitation = EventInvitation(
          invitationId: invitationId,
          eventId: _selectedEventId!,
          nim: nim,
          responseStatus: 'pending',
          responseMessage: null,
          respondedAt: null,
          attendanceStatus: 'not_marked',
          attendanceTime: attendanceTime,
          invitedBy: invitedBy,
          invitedAt: DateTime.now(),
          isRequired: true,
          isSynced: false,
        );

        await HiveService.invitations.put(invitationId, invitation);
      }

      CustomSnackbar.showSuccess(
        context,
        'Undangan berhasil dikirim ke ${selected.length} anggota. (Sinkronisasi tertunda)',
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.showError(context, 'Gagal mengirim undangan: $e');
    }
  }

  void _confirmAndSend() {
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    if (selectedCount == 0) {
      CustomSnackbar.showError(
        context,
        'Pilih minimal satu anggota terlebih dahulu.',
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengiriman'),
        content: Text('Kirim undangan ke $selectedCount anggota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              _sendInvitations();
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser.value;
    final role = (currentUser?.role ?? '').trim().toLowerCase();
    final allowed = [
      AppConstants.roleExecutive.toLowerCase(),
      AppConstants.roleManager.toLowerCase()
    ];

    if (!allowed.contains(role)) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          title: const Text('Kelola Target Peserta'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                const Text('Akses Ditolak',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'Halaman ini hanya dapat diakses oleh Executive atau Manager.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                  ),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    InvitationHeader(
                      onBackPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          RefreshIndicator(
                            onRefresh: _loadData,
                            child: SectionedListBody(
                              searchPadding: const EdgeInsets.fromLTRB(16, 80, 16, 10),
                              searchArea: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.grey.shade100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedEventId,
                                    items: _events
                                        .map((e) => DropdownMenuItem(
                                              value: e.eventId,
                                              child: Text(
                                                '${e.nama} - ${DateFormat('dd MMM yyyy', 'id_ID').format(e.tanggalMulai)}',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedEventId = val),
                                  ),
                                ),
                              ),
                              filterArea: ValueListenableBuilder<String>(
                                valueListenable: _selectedRoleFilter,
                                builder: (context, selected, _) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          RoleFilterChip(
                                            label: 'Semua',
                                            isSelected: selected == 'Semua',
                                            selectedColor: Colors.grey.shade600,
                                            onTap: () => _selectedRoleFilter.value = 'Semua',
                                          ),
                                          const SizedBox(width: 8),
                                          RoleFilterChip(
                                            label: 'Member',
                                            isSelected: selected == 'Member',
                                            selectedColor: const Color(0xFF2563EB),
                                            onTap: () => _selectedRoleFilter.value = 'Member',
                                          ),
                                          const SizedBox(width: 8),
                                          RoleFilterChip(
                                            label: 'Manager',
                                            isSelected: selected == 'Manager',
                                            selectedColor: const Color(0xFF7C3AED),
                                            onTap: () => _selectedRoleFilter.value = 'Manager',
                                          ),
                                          const SizedBox(width: 8),
                                          RoleFilterChip(
                                            label: 'Executive',
                                            isSelected: selected == 'Executive',
                                            selectedColor: const Color(0xFF0EA5A4),
                                            onTap: () => _selectedRoleFilter.value = 'Executive',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Content juga ikut rebuild saat filter berubah
                              content: ValueListenableBuilder<String>(
                                valueListenable: _selectedRoleFilter,
                                builder: (context, filter, _) {
                                  return MemberSelectionList(
                                    roleFilter: filter,
                                    selectedMembers: _selectedMembers,
                                    onMemberToggle: (nim, value) {
                                      setState(() => _selectedMembers[nim] = value);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),

                          // Stats Overlay
                          Positioned(
                            top: 80,
                            left: 16,
                            right: 16,
                            child: InvitationStatsSection(
                              totalMembers: HiveService.members.length,
                              selectedCount: _selectedMembers.values.where((v) => v).length,
                              pendingInvites: HiveService.invitations.values
                                  .where((inv) => inv.responseStatus == 'pending')
                                  .length,
                            ),
                          ),

                          // Action Bar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: InvitationActionBar(
                              selectedCount: _selectedMembers.values.where((v) => v).length,
                              onSendPressed: _confirmAndSend,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}