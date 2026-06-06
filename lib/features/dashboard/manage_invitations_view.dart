import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../models/event_invitation.dart';
import '../../models/member_model.dart';
import '../auth/auth_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../event/event_permission.dart';
import 'widgets/invitation_event_selector.dart';
import 'widgets/invitation_summary_cards.dart';
import 'widgets/invitation_member_list.dart';

class ManageInvitationsView extends StatefulWidget {
  const ManageInvitationsView({super.key});

  @override
  State<ManageInvitationsView> createState() => _ManageInvitationsViewState();
}

class _ManageInvitationsViewState extends State<ManageInvitationsView> {
  List<EventModel> _events = [];
  Map<String, bool> _selectedMembers = {};
  String? _selectedMainEventId;
  String? _selectedSubEventId;
  bool _isLoading = true;

  // Search and Filter State
  String _searchQuery = '';
  String _filterRole = 'Semua';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final events = HiveService.events.values.toList();
      final members = HiveService.members.values.toList();

      setState(() {
        _events = events;
        _selectedMembers = {for (final m in members) m.nim: false};
        _syncEventSelection();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      CustomSnackbar.showError(context, 'Gagal memuat data: $e');
    }
  }

  List<EventModel> get _mainEvents =>
      _events.where((e) => e.parentEventId == null && e.requiresInvitation).toList(growable: false);

  List<EventModel> get _subEventsForSelectedMain {
    final mainId = _selectedMainEventId;
    if (mainId == null) return const <EventModel>[];
    return _events
        .where((e) => e.parentEventId == mainId && e.requiresInvitation)
        .toList(growable: false);
  }

  String? get _selectedTargetEventId {
    return _selectedSubEventId ?? _selectedMainEventId;
  }

  List<MemberModel> get _filteredMembers {
    final allMembers = HiveService.members.values.toList();
    return allMembers.where((m) {
      final matchSearch = m.nama.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                          m.nim.contains(_searchQuery);
      final matchRole = _filterRole == 'Semua' || m.role.toLowerCase() == _filterRole.toLowerCase();
      return matchSearch && matchRole;
    }).toList();
  }

  void _syncEventSelection() {
    if (_mainEvents.isEmpty) {
      _selectedMainEventId = null;
      _selectedSubEventId = null;
      return;
    }

    final mainExists =
        _selectedMainEventId != null &&
        _mainEvents.any((e) => e.eventId == _selectedMainEventId);
    if (!mainExists) {
      _selectedMainEventId = _mainEvents.first.eventId;
    }

    final subEvents = _subEventsForSelectedMain;
    if (subEvents.isEmpty) {
      _selectedSubEventId = null;
      return;
    }

    final subExists =
        _selectedSubEventId != null &&
        subEvents.any((e) => e.eventId == _selectedSubEventId);
    if (!subExists) {
      _selectedSubEventId = subEvents.first.eventId;
    }
  }

  void _onMainEventChanged(String? value) {
    if (value == null) return;
    final subEvents = _events
        .where((e) => e.parentEventId == value)
        .toList(growable: false);

    setState(() {
      _selectedMainEventId = value;
      _selectedSubEventId = subEvents.isEmpty ? null : subEvents.first.eventId;
    });
  }

  void _toggleAllFilteredMembers() {
    final currentFiltered = _filteredMembers;
    if (currentFiltered.isEmpty) return;

    final allSelected = currentFiltered.every((m) => _selectedMembers[m.nim] == true);
    setState(() {
      for (final m in currentFiltered) {
        _selectedMembers[m.nim] = !allSelected;
      }
    });
  }

  Future<void> _sendInvitations() async {
    final targetEventId = _selectedTargetEventId;
    if (targetEventId == null) return;

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
      final event = HiveService.events.get(targetEventId);
      final attendanceTime = event?.tanggalMulai ?? DateTime.now();

      for (final nim in selected) {
        final invitation = EventInvitation(
          eventId: targetEventId,
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

        await HiveService.invitations.put(invitation.compositeKey, invitation);
      }

      if (!mounted) return;
      CustomSnackbar.showSuccess(
        context,
        'Undangan berhasil disebar ke ${selected.length} anggota! Data sinkronisasi tertunda karena offline mode (Simulasi).',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Gagal mengirim undangan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser.value;
    final role = (currentUser?.role ?? '').trim().toLowerCase();
    
    // We check if the user has permission to manage events. 
    // In dynamic RBAC, those who can create/update events should be able to manage their invitations.
    final canManage = EventPermission.canCreateMainEvent(role) || 
                      EventPermission.canCreateSubEvent(role) ||
                      role == 'organizer'; // Fallback for backward compatibility

    if (!canManage) {
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
                const Text('Akses Ditolak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Halaman ini hanya dapat diakses oleh pembuat event atau panitia.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text('Kembali'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalAnggota = HiveService.members.length;
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    // Menggunakan data mock 12 untuk undangan yang menunggu seperti di JS
    final pendingCount = 12;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Kelola Target Peserta', 
          style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InvitationEventSelector(
                  mainEvents: _mainEvents,
                  selectedMainEventId: _selectedMainEventId,
                  onMainEventChanged: _onMainEventChanged,
                  subEventsForSelectedMain: _subEventsForSelectedMain,
                  selectedSubEventId: _selectedSubEventId,
                  onSubEventChanged: (val) {
                    if (val != null) setState(() => _selectedSubEventId = val);
                  },
                ),
                const SizedBox(height: 16),
                InvitationSummaryCards(
                  totalAnggota: totalAnggota,
                  selectedCount: selectedCount,
                  pendingCount: pendingCount,
                ),
                const SizedBox(height: 16),
                InvitationMemberList(
                  filteredMembers: _filteredMembers,
                  selectedMembers: _selectedMembers,
                  filterRole: _filterRole,
                  onSearchQueryChanged: (val) => setState(() => _searchQuery = val),
                  onFilterRoleChanged: (val) => setState(() => _filterRole = val),
                  onToggleAll: _toggleAllFilteredMembers,
                  onToggleMember: (nim, val) => setState(() => _selectedMembers[nim] = val),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendInvitations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: const Color(0xFFBFDBFE),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Kirim Undangan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
    );
  }
}
