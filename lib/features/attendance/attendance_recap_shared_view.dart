import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/gradient_header.dart';
import '../../core/auth/attendance_role_policy.dart';
import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../widgets/sectioned_list_body.dart';
import '../auth/auth_controller.dart';
import '../event/event_controller.dart';
import 'attendance_controller.dart';
import 'widgets/attendance_records_table.dart';
import 'widgets/event_selector_field.dart';

class AttendanceRecapSharedView extends StatefulWidget {
  final String title;
  final AttendanceRolePolicy policy;
  final String? initialEventId;
  const AttendanceRecapSharedView({
    super.key,
    required this.title,
    required this.policy,
    this.initialEventId,
  });
  @override
  State<AttendanceRecapSharedView> createState() =>
      _AttendanceRecapSharedViewState();
}

class _AttendanceRecapSharedViewState extends State<AttendanceRecapSharedView> {
  bool _isLoading = true;
  List<EventModel> _events = const [];
  List<AttendanceRecord> _records = const [];
  Map<String, MemberModel> _memberById = const {};
  String? _selectedEventId;

  String get _currentRole =>
      (AuthController.instance.currentUser.value?.role ?? '').trim();

  bool get _hasAccess {
    if (_currentRole == AppConstants.roleExecutive.toLowerCase()) {
      return true;
    }
    if (_currentRole == AppConstants.roleManager.toLowerCase()) {
      return widget.policy.canEditStatus || widget.policy.canDeleteRecord;
    }
    if (_currentRole == AppConstants.roleOrganizer.toLowerCase()) {
      return !widget.policy.canEditStatus && !widget.policy.canDeleteRecord;
    }
    return false;
  }
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    // Tarik data terbaru dari MongoDB Cloud
    await EventController.instance.loadEvents(force: true);

    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));
    final records = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final members = HiveService.members.values.toList(growable: false);
    final map = <String, MemberModel>{for (final m in members) m.nim: m};
    String? selected = _selectedEventId ?? widget.initialEventId;
    if (selected == null && events.isNotEmpty) {
      selected = events.first.eventId;
    }
    if (selected != null && !events.any((e) => e.eventId == selected)) {
      selected = events.isNotEmpty ? events.first.eventId : null;
    }
    if (!mounted) return;
    setState(() {
      _events = events;
      _records = records;
      _memberById = map;
      _selectedEventId = selected;
      _isLoading = false;
    });
  }

  List<AttendanceRecord> get _filteredRecords {
    if (_selectedEventId == null) return const [];
    return _records
        .where((r) => r.eventId == _selectedEventId)
        .toList(growable: false);
  }

  String _eventLabel(String eventId) {
    final event = _events.where((e) => e.eventId == eventId).toList();
    if (event.isEmpty) return eventId;
    final e = event.first;
    if (e.parentEventId == null) {
      return 'Event Utama - ${e.nama}';
    }
    final parent = _events.where((x) => x.eventId == e.parentEventId).toList();
    final parentName = parent.isEmpty ? 'Unknown' : parent.first.nama;
    return 'Sub-Event - $parentName / ${e.nama}';
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _editStatus(AttendanceRecord record) async {
    String selected = record.status == 'Ditolak' ? 'Ditolak' : 'Hadir';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Status Kehadiran'),
              content: DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'Ditolak', child: Text('Ditolak')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() {
                    selected = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    final managerId = AuthController.instance.currentUser.value?.nim ?? 'system';
    final ok = await AttendanceController.instance.overrideAttendanceStatus(
      recordId: record.recordId,
      newStatus: selected,
      overrideById: managerId,
    );
    if (!mounted) return;
    if (!ok) {
      _showMessage('Gagal memperbarui status kehadiran.', isError: true);
      return;
    }
    await _refresh();
    if (!mounted) return;
    _showMessage('Status kehadiran berhasil diperbarui.');
  }

  Future<void> _deleteRecord(AttendanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return const CustomConfirmDialog(
          title: 'Hapus Kehadiran',
          content: 'Yakin ingin menghapus record kehadiran ini?',
          isDestructive: true,
          confirmText: 'Hapus',
        );
      },
    );
    if (confirmed != true) return;
    final ok = await AttendanceController.instance.deleteAttendanceRecord(
      record.recordId,
    );
    if (!mounted) return;
    if (!ok) {
      _showMessage('Gagal menghapus data kehadiran.', isError: true);
      return;
    }
    await _refresh();
    if (!mounted) return;
    _showMessage('Record kehadiran berhasil dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: GradientHeader(
          title: widget.title,
          subtitle: 'Akses terbatas',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Role Anda tidak memiliki akses ke halaman rekap ini.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GradientHeader(
        title: widget.title,
        subtitle: 'Ringkasan rekap kehadiran',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? const Center(child: Text('Belum ada event/sub-event tersedia.'))
          : SectionedListBody(
              searchArea: EventSelectorField(
                selectedEventId: _selectedEventId,
                events: _events,
                labelBuilder: _eventLabel,
                onChanged: (value) {
                  setState(() {
                    _selectedEventId = value;
                  });
                },
              ),
              content: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: AttendanceRecordsTable(
                          records: _filteredRecords,
                          memberById: _memberById,
                          eventLabelBuilder: _eventLabel,
                          showEventColumn: true,
                          showActionColumn: widget.policy.hasActionColumn,
                          enableFilters: true,
                          onEdit: widget.policy.canEditStatus
                            ? _editStatus
                            : null,
                        onDelete: widget.policy.canDeleteRecord
                            ? _deleteRecord
                            : null,
                        emptyText: 'Belum ada data kehadiran pada event ini.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
