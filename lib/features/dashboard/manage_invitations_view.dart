// ignore_for_file: unused_import

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../models/event_invitation.dart';
import '../../models/member_model.dart';
import '../auth/auth_controller.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/empty_state_widget.dart';

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
  final ValueNotifier<String> _selectedRoleFilter = ValueNotifier<String>(
    'Semua',
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load events and members from Hive
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
      _events.where((e) => e.parentEventId == null).toList(growable: false);

  List<EventModel> get _subEventsForSelectedMain {
    final mainId = _selectedMainEventId;
    if (mainId == null) return const <EventModel>[];
    return _events
        .where((e) => e.parentEventId == mainId)
        .toList(growable: false);
  }

  String? get _selectedTargetEventId {
    return _selectedSubEventId ?? _selectedMainEventId;
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
        final invitationId =
            'INV-${DateTime.now().millisecondsSinceEpoch}-${nim}';
        final invitation = EventInvitation(
          invitationId: invitationId,
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

  // ─────────────────── HELPER METHODS ───────────────────

  /// Get role badge color based on role type
  Color _getRoleBadgeColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFFE0E7FF); // Indigo light
    if (lowerRole == 'manager') return const Color(0xFFFCE7F3); // Pink light
    if (lowerRole == 'executive') return const Color(0xFFF0FDFA); // Teal light
    return const Color(0xFFF3F4F6); // Gray light
  }

  /// Get role text color based on role type
  Color _getRoleTextColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFF4F46E5); // Indigo
    if (lowerRole == 'manager') return const Color(0xFFDB2777); // Pink
    if (lowerRole == 'executive') return const Color(0xFF0D9488); // Teal
    return const Color(0xFF6B7280); // Gray
  }

  /// Get avatar background color based on role (blue gradient variations)
  Color _getAvatarColor(String role) {
    final lowerRole = role.toLowerCase();
    if (lowerRole == 'member') return const Color(0xFF3B82F6); // Blue
    if (lowerRole == 'manager') return const Color(0xFF2563EB); // Darker blue
    if (lowerRole == 'executive')
      return const Color(0xFF1D4ED8); // Even darker blue
    return const Color(0xFF60A5FA); // Light blue
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthController.instance.currentUser.value;
    final role = (currentUser?.role ?? '').trim().toLowerCase();
    final allowed = [
      AppConstants.roleExecutive.toLowerCase(),
      AppConstants.roleManager.toLowerCase(),
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
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akses Ditolak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                // Main Content Column
                Column(
                  children: [
                    // Custom Curved Header
                    _buildCurvedHeader(),

                    // Sticky Top Area: Statistics Cards + Event Selector + Filters
                    Container(
                      color: const Color(0xFFF3F7FD),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        children: [
                          // Statistics Cards
                          _buildStatisticsCards(),
                          const SizedBox(height: 14),

                          // Event selector
                          _buildEventSelector(),
                          const SizedBox(height: 12),

                          // Role filter chips
                          ValueListenableBuilder<String>(
                            valueListenable: _selectedRoleFilter,
                            builder: (context, selected, _) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _roleChip(
                                      'Semua',
                                      selected == 'Semua',
                                      Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    ...AppConstants.penyelenggaraOptions.map(
                                      (option) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: _roleChip(
                                          option,
                                          selected == option,
                                          const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Member List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: [
                            // Member list or empty
                            _buildMemberList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Sticky Bottom Action Bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyActionBar(),
                ),
              ],
            ),
    );
  }

  /// Build custom curved header with back button and title
  Widget _buildCurvedHeader() {
    return ClipPath(
      clipper: CurvedHeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelola Target Peserta',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih peserta dan kirim undangan',
                        style: TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build statistics cards with overlapping effect
  Widget _buildStatisticsCards() {
    final totalMembers = HiveService.members.length;
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    final pendingInvites = HiveService.invitations.values
        .where((inv) => inv.responseStatus == 'pending')
        .length;

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          // Total Anggota
          Expanded(
            child: _statisticCard(
              label: 'Total Anggota',
              value: '$totalMembers',
              icon: Icons.people,
              backgroundColor: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              accentColor: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          // Terpilih
          Expanded(
            child: _statisticCard(
              label: 'Terpilih',
              value: '$selectedCount',
              icon: Icons.check_circle,
              backgroundColor: const Color(0xFFFDE68A),
              iconColor: const Color(0xFFF59E0B),
              accentColor: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          // Menunggu
          Expanded(
            child: _statisticCard(
              label: 'Menunggu',
              value: '$pendingInvites',
              icon: Icons.mail_outline,
              backgroundColor: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
              accentColor: const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistic card widget
  Widget _statisticCard({
    required String label,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build a responsive event dropdown that stays compact on mobile.
  Widget _buildEventSelector() {
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDropdownHeight = math.min(screenHeight * 0.42, 360.0);

    if (_mainEvents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const Text(
          'Belum ada Main Event yang tersedia.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main Event',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedMainEventId,
            isExpanded: true,
            isDense: true,
            menuMaxHeight: maxDropdownHeight,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            borderRadius: BorderRadius.circular(16),
            dropdownColor: Colors.white,
            hint: const Text('Pilih Main Event'),
            items: _mainEvents
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.eventId,
                    child: Text(
                      e.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _onMainEventChanged,
          ),
          const SizedBox(height: 12),
          if (_subEventsForSelectedMain.isNotEmpty) ...[
            Text(
              'Sub Event',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedSubEventId,
              isExpanded: true,
              isDense: true,
              menuMaxHeight: maxDropdownHeight,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(16),
              dropdownColor: Colors.white,
              hint: const Text('Pilih Sub Event'),
              items: _subEventsForSelectedMain
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.eventId,
                      child: Text(
                        e.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() => _selectedSubEventId = value);
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Build member list with modern card design
  Widget _buildMemberList() {
    final roleFilter = _selectedRoleFilter.value;
    final members = HiveService.members.values.where((m) {
      if (roleFilter == 'Semua') return true;
      return m.divisi == roleFilter;
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
      children: members
          .map((m) {
            final nim = m.nim;
            final selected = _selectedMembers[nim] ?? false;
            final initials = _getInitials(m.nama);
            final avatarColor = _getAvatarColor(m.role);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDBEAFE).withValues(alpha: 0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade100,
                  width: selected ? 2 : 1,
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
                      onTap: () =>
                          setState(() => _selectedMembers[nim] = !selected),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : Colors.white,
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
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
                            m.nama,
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
                            'NIM: ${m.nim}',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleBadgeColor(m.role),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        m.role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getRoleTextColor(m.role),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  /// Build sticky bottom action bar
  Widget _buildStickyActionBar() {
    final selectedCount = _selectedMembers.values.where((v) => v).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          // Selection indicator
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '$selectedCount peserta dipilih',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),

          // Main action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selectedCount > 0
                  ? _confirmAndSend
                  : () {
                      CustomSnackbar.showError(
                        context,
                        'Pilih minimal satu anggota terlebih dahulu.',
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCount > 0
                    ? const Color(0xFF2563EB)
                    : Colors.grey.shade300,
                foregroundColor: selectedCount > 0
                    ? Colors.white
                    : Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: selectedCount > 0 ? 3 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Kirim Undangan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (selectedCount > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedCount',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build role filter chip
  Widget _roleChip(String label, bool selected, Color color) {
    return InkWell(
      onTap: () => _selectedRoleFilter.value = label,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// Get initials from name
  String _getInitials(String nama) {
    final parts = nama.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Show confirmation dialog before sending invitations
  void _confirmAndSend() {
    final selected = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (selected.isEmpty) {
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
        content: Text('Kirim undangan ke ${selected.length} anggota?'),
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
}

/// Custom clipper for curved header
class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);

    // Create smooth curve
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CurvedHeaderClipper oldClipper) => false;
}
