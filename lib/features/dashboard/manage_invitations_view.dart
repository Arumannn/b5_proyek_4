import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../models/event_invitation.dart';
import '../../models/member_model.dart';
import '../auth/auth_controller.dart';
import '../../widgets/custom_snackbar.dart';

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
        final invitationId =
            'INV-${DateTime.now().millisecondsSinceEpoch}-$nim';
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
        'Undangan berhasil disebar ke ${selected.length} anggota! Data sinkronisasi tertunda karena offline mode (Simulasi).',
      );
      Navigator.pop(context);
    } catch (e) {
      CustomSnackbar.showError(context, 'Gagal mengirim undangan: $e');
    }
  }

  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // bg-gray-50
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14), // text-gray-800 text-sm
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildEventSelector() {
    if (_mainEvents.isEmpty) {
      return Container(
        width: double.infinity,
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
            ),
          ],
        ),
        child: const Text(
          'Belum ada event yang tersedia.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PILIH EVENT/SUB-EVENT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151), // text-gray-700
              letterSpacing: 0.5, // tracking-wide
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _selectedMainEventId,
            items: _mainEvents
                .map((e) => DropdownMenuItem(
                      value: e.eventId,
                      child: Text(e.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: _onMainEventChanged,
            hint: 'Pilih Event Utama',
          ),
          if (_subEventsForSelectedMain.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDropdown(
              value: _selectedSubEventId,
              items: _subEventsForSelectedMain
                  .map((e) => DropdownMenuItem(
                        value: e.eventId,
                        child: Text(e.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSubEventId = val);
              },
              hint: 'Pilih Sub-Event',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalAnggota = HiveService.members.length;
    final selectedCount = _selectedMembers.values.where((v) => v).length;
    // Menggunakan data mock 12 untuk undangan yang menunggu seperti di JS
    final pendingCount = 12;

    return Row(
      children: [
        _buildSummaryBox(
          label: 'Total Anggota',
          count: totalAnggota,
          bgColor: const Color(0xFFEFF6FF), // bg-blue-50
          borderColor: const Color(0xFFDBEAFE), // border-blue-100
          labelColor: const Color(0xFF2563EB), // text-blue-600
          countColor: const Color(0xFF1E40AF), // text-blue-800
        ),
        const SizedBox(width: 12),
        _buildSummaryBox(
          label: 'Terpilih',
          count: selectedCount,
          bgColor: const Color(0xFFF0FDF4), // bg-green-50
          borderColor: const Color(0xFFDCFCE7), // border-green-100
          labelColor: const Color(0xFF16A34A), // text-green-600
          countColor: const Color(0xFF166534), // text-green-800
        ),
        const SizedBox(width: 12),
        _buildSummaryBox(
          label: 'Menunggu',
          count: pendingCount,
          bgColor: const Color(0xFFFFF7ED), // bg-orange-50
          borderColor: const Color(0xFFFFEDD5), // border-orange-100
          labelColor: const Color(0xFFEA580C), // text-orange-600
          countColor: const Color(0xFF9A3412), // text-orange-800
        ),
      ],
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required int count,
    required Color bgColor,
    required Color borderColor,
    required Color labelColor,
    required Color countColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12), // p-3
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10, // text-[10px]
                fontWeight: FontWeight.bold,
                color: labelColor,
                letterSpacing: 0.5, // tracking-wide
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20, // text-xl
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberList() {
    final filteredUsers = _filteredMembers;
    final allSelected = filteredUsers.isNotEmpty && filteredUsers.every((m) => _selectedMembers[m.nim] == true);

    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          )
        ], // shadow-sm
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
                  fontSize: 12, // text-xs
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151), // text-gray-700
                  letterSpacing: 0.5, // uppercase tracking-wide
                ),
              ),
              GestureDetector(
                onTap: _toggleAllFilteredMembers,
                child: Text(
                  allSelected ? 'Batal Semua' : 'Pilih Semua',
                  style: const TextStyle(
                    fontSize: 12, // text-xs
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB), // text-blue-600
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12), // mb-3
          
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB), // bg-gray-50
              borderRadius: BorderRadius.circular(12), // rounded-xl
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
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
          
          const SizedBox(height: 12), // mb-3
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Executive', 'Manager', 'Organizer', 'Member'].map((role) {
                final isSelected = _filterRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _filterRole = role),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // px-4 py-1.5
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white, // bg-blue-600 / bg-white
                        borderRadius: BorderRadius.circular(999), // rounded-full
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
                          fontSize: 12, // text-xs
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563), // text-white / text-gray-600
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 12), // mt-3
          
          // Member List
          Container(
            constraints: const BoxConstraints(maxHeight: 240), // max-h-60 (240px)
            child: filteredUsers.isEmpty
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
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isSelected = _selectedMembers[user.nim] ?? false;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMembers[user.nim] = !isSelected;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12), // p-3
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFF9FAFB) : Colors.white, // hover:bg-gray-50
                            border: Border.all(color: Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(8), // rounded-lg
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
                                      setState(() {
                                        _selectedMembers[user.nim] = val;
                                      });
                                    }
                                  },
                                  activeColor: const Color(0xFF2563EB), // text-blue-600
                                  side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 12), // ml-3
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.nama,
                                      style: const TextStyle(
                                        fontSize: 14, // text-sm
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937), // text-gray-800
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${user.role} • ${user.nim}',
                                      style: const TextStyle(
                                        fontSize: 10, // text-[10px]
                                        color: Color(0xFF6B7280), // text-gray-500
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
                const Text('Akses Ditolak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Halaman ini hanya dapat diakses oleh Executive atau Manager.', textAlign: TextAlign.center),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
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
              padding: const EdgeInsets.all(16), // p-4
              children: [
                _buildEventSelector(),
                const SizedBox(height: 16), // space-y-4
                _buildSummaryCards(),
                const SizedBox(height: 16), // space-y-4
                _buildMemberList(),
                const SizedBox(height: 16), // space-y-4
                ElevatedButton(
                  onPressed: _sendInvitations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // bg-blue-600
                    foregroundColor: Colors.white, // text-white
                    padding: const EdgeInsets.symmetric(vertical: 16), // py-4
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // rounded-xl
                    elevation: 4, // shadow-lg
                    shadowColor: const Color(0xFFBFDBFE), // shadow-blue-200
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18), // Send size={18}
                      SizedBox(width: 8), // mr-2
                      Text(
                        'Kirim Undangan Massal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // pb-20 in the main container
              ],
            ),
    );
  }
}