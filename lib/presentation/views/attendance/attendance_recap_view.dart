// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/gradient_header.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/custom_snackbar.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/custom_confirm_dialog.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/domain/controllers/attendance/attendance_controller.dart';
import 'package:b5_proyek_4/domain/permissions/attendance/attendance_permission.dart';
import 'package:b5_proyek_4/presentation/views/attendance/scan_screen.dart';
import 'package:b5_proyek_4/presentation/widgets/attendance/read_only_recap_body.dart';
import 'package:b5_proyek_4/presentation/widgets/attendance/crud_recap_body.dart';

enum RecapMode { byMainEvent, bySubEvent, aggregateByMainEvent, global }

class AttendanceRecapView extends StatefulWidget {
  const AttendanceRecapView({super.key});

  @override
  State<AttendanceRecapView> createState() => _AttendanceRecapViewState();
}

class _AttendanceRecapViewState extends State<AttendanceRecapView> {
  bool _isLoading = true;
  List<EventModel> _events = const <EventModel>[];
  List<AttendanceRecord> _records = const <AttendanceRecord>[];
  Map<String, MemberModel> _memberById = const <String, MemberModel>{};
  Map<String, EventModel> _eventById = const <String, EventModel>{};
  Map<String, List<String>> _subEventIdsByMain = const <String, List<String>>{};

  RecapMode _recapMode = RecapMode.byMainEvent;
  String? _selectedMainEventId;
  String? _selectedSubEventId;
  String? _selectedReadOnlyEventId;

  String get _role =>
      (AuthController.instance.currentUser.value?.role ??
              AppConstants.roleMember)
          .trim()
          .toLowerCase();

  bool get _canCrud => AttendancePermission.hasActionColumn(_role);

  bool get _canViewRecap => AttendancePermission.canViewRecap(_role);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

    final records = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final members = HiveService.members.values.toList(growable: false);
    final memberById = <String, MemberModel>{
      for (final m in members) m.nim: m,
    };
    final eventById = <String, EventModel>{
      for (final e in events) e.eventId: e,
    };

    final mains = events
        .where((e) => e.parentEventId == null)
        .toList(growable: false);
    final subByMain = <String, List<String>>{};
    for (final main in mains) {
      subByMain[main.eventId] = <String>[];
    }
    for (final event in events) {
      final parentId = event.parentEventId;
      if (parentId != null && subByMain.containsKey(parentId)) {
        subByMain[parentId]!.add(event.eventId);
      }
    }

    String? selectedMain = _selectedMainEventId;
    if (selectedMain == null && mains.isNotEmpty) {
      selectedMain = mains.first.eventId;
    }
    if (selectedMain != null && !mains.any((e) => e.eventId == selectedMain)) {
      selectedMain = mains.isNotEmpty ? mains.first.eventId : null;
    }

    final subIds = selectedMain == null
        ? const <String>[]
        : (subByMain[selectedMain] ?? const <String>[]);
    String? selectedSub = _selectedSubEventId;
    if (selectedSub == null && subIds.isNotEmpty) {
      selectedSub = subIds.first;
    }
    if (selectedSub != null && !subIds.contains(selectedSub)) {
      selectedSub = subIds.isNotEmpty ? subIds.first : null;
    }

    String? selectedReadOnly = _selectedReadOnlyEventId;
    if (selectedReadOnly == null && events.isNotEmpty) {
      selectedReadOnly = events.first.eventId;
    }
    if (selectedReadOnly != null &&
        !events.any((e) => e.eventId == selectedReadOnly)) {
      selectedReadOnly = events.isNotEmpty ? events.first.eventId : null;
    }

    if (!mounted) return;
    setState(() {
      _events = events;
      _records = records;
      _memberById = memberById;
      _eventById = eventById;
      _subEventIdsByMain = subByMain;
      _selectedMainEventId = selectedMain;
      _selectedSubEventId = selectedSub;
      _selectedReadOnlyEventId = selectedReadOnly;
      _isLoading = false;
    });
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  List<EventModel> get _mainEvents =>
      _events.where((e) => e.parentEventId == null).toList(growable: false);

  List<EventModel> get _subEventsForSelectedMain {
    final mainId = _selectedMainEventId;
    if (mainId == null) return const <EventModel>[];
    final ids = _subEventIdsByMain[mainId] ?? const <String>[];
    return ids
        .map((id) => _eventById[id])
        .whereType<EventModel>()
        .toList(growable: false);
  }

  List<AttendanceRecord> get _filteredCrudRecords {
    switch (_recapMode) {
      case RecapMode.byMainEvent:
        final mainId = _selectedMainEventId;
        if (mainId == null) return const <AttendanceRecord>[];
        return _records
            .where((r) => r.eventId == mainId)
            .toList(growable: false);
      case RecapMode.bySubEvent:
        final subId = _selectedSubEventId;
        if (subId == null) return const <AttendanceRecord>[];
        return _records
            .where((r) => r.eventId == subId)
            .toList(growable: false);
      case RecapMode.aggregateByMainEvent:
        final mainId = _selectedMainEventId;
        if (mainId == null) return const <AttendanceRecord>[];
        final allowed = <String>{mainId, ...?_subEventIdsByMain[mainId]};
        return _records
            .where((r) => allowed.contains(r.eventId))
            .toList(growable: false);
      case RecapMode.global:
        return List<AttendanceRecord>.from(_records, growable: false);
    }
  }

  List<AttendanceRecord> get _readOnlyRecords {
    final eventId = _selectedReadOnlyEventId;
    if (eventId == null) return const <AttendanceRecord>[];
    
    var records = _records.where((r) => r.eventId == eventId);
    
    final currentUser = AuthController.instance.currentUser.value;
    if (currentUser != null) {
      final role = currentUser.role.trim().toLowerCase();
      final isOrganizer = ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleOrganizer);
      final isMember = ConfigController.instance.roleMatchesConfiguredName(role, AppConstants.roleMember);
      if (isOrganizer || isMember) {
        records = records.where((r) => r.nim == currentUser.nim);
      }
    }
    
    return records.toList(growable: false);
  }

  String _eventLabel(String eventId) {
    final event = _eventById[eventId];
    if (event == null) return eventId;
    if (event.parentEventId == null) return 'Event Utama - ${event.nama}';
    final parent = _eventById[event.parentEventId!]?.nama ?? 'Unknown';
    return 'Sub-Event - $parent / ${event.nama}';
  }

  String _modeLabel(RecapMode mode) {
    switch (mode) {
      case RecapMode.byMainEvent:
        return 'Berdasarkan Main Event';
      case RecapMode.bySubEvent:
        return 'Berdasarkan Sub-Event';
      case RecapMode.aggregateByMainEvent:
        return 'Rekap Keseluruhan dalam Main Event';
      case RecapMode.global:
        return 'Rekap Global';
    }
  }

  String? get _currentCrudEventId {
    switch (_recapMode) {
      case RecapMode.byMainEvent:
        return _selectedMainEventId;
      case RecapMode.bySubEvent:
        return _selectedSubEventId;
      case RecapMode.aggregateByMainEvent:
      case RecapMode.global:
        return null;
    }
  }

  bool get _isMainEventCrudBlocked {
    if (_recapMode != RecapMode.byMainEvent) return false;
    final mainId = _selectedMainEventId;
    if (mainId == null) return false;
    final subIds = _subEventIdsByMain[mainId] ?? const <String>[];
    return subIds.isNotEmpty;
  }

  Future<void> _openScanQr() async {
    final eventId = _currentCrudEventId;
    if (eventId == null) {
      CustomSnackbar.showWarning(
        context,
        'Gunakan mode Main Event/Sub-Event untuk melakukan scan QR.',
      );
      return;
    }

    if (_isMainEventCrudBlocked) {
      CustomSnackbar.showWarning(
        context,
        'Main event ini punya sub-event. Scan absensi hanya boleh di sub-event.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ScanScreen(eventId: eventId)),
    );
    await _refresh();
  }

  Future<void> _addManualAttendance() async {
    final eventId = _currentCrudEventId;
    if (eventId == null) {
      CustomSnackbar.showWarning(
        context,
        'Tambah manual hanya tersedia pada mode Main Event/Sub-Event.',
      );
      return;
    }

    if (_isMainEventCrudBlocked) {
      CustomSnackbar.showWarning(
        context,
        'Main event ini punya sub-event. Tambah absensi manual hanya di sub-event.',
      );
      return;
    }

    final members = _memberById.values.toList(growable: false)
      ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
    if (members.isEmpty) {
      CustomSnackbar.showWarning(context, 'Belum ada anggota terdaftar.');
      return;
    }

    String selectedStatus = 'Hadir';
    String selectedNim = members.first.nim;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Kehadiran Manual'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedNim,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Anggota',
                    ),
                    items: members
                        .map(
                          (m) => DropdownMenuItem<String>(
                            value: m.nim,
                            child: Text('${m.nim} - ${m.nama}'),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedNim = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'Hadir',
                        child: Text('Hadir'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Ditolak',
                        child: Text('Ditolak'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ],
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

    if (saved != true) return;

    final ok = await AttendanceController.instance.addManualAttendance(
      eventId: eventId,
      nim: selectedNim,
      status: selectedStatus,
    );

    if (!mounted) return;
    if (!ok) {
      CustomSnackbar.showError(
        context,
        'Gagal menambah data. Pastikan tidak ada absensi ganda.',
      );
      return;
    }

    await _refresh();
    if (!mounted) return;
    CustomSnackbar.showSuccess(context, 'Data kehadiran berhasil ditambahkan.');
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
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem<String>(
                    value: 'Hadir',
                    child: Text('Hadir'),
                  ),
                  DropdownMenuItem<String>(
                    value: 'Ditolak',
                    child: Text('Ditolak'),
                  ),
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

    final managerId = AuthController.instance.currentUser.value?.nim ?? 'manager';
    final ok = await AttendanceController.instance.overrideAttendanceStatus(
      recordId: record.recordId,
      newStatus: selected,
      overrideById: managerId,
    );

    if (!mounted) return;
    if (!ok) {
      CustomSnackbar.showError(context, 'Gagal memperbarui status kehadiran.');
      return;
    }

    await _refresh();
    if (!mounted) return;
    CustomSnackbar.showSuccess(
      context,
      'Status kehadiran berhasil diperbarui.',
    );
  }

  Future<void> _deleteRecord(AttendanceRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return const CustomConfirmDialog(
          title: 'Hapus Kehadiran',
          content: 'Yakin ingin menghapus record kehadiran ini?',
          confirmText: 'Hapus',
          isDestructive: true,
        );
      },
    );

    if (confirmed != true) return;

    final ok = await AttendanceController.instance.deleteAttendanceRecord(
      record.recordId,
    );

    if (!mounted) return;
    if (!ok) {
      CustomSnackbar.showError(context, 'Gagal menghapus data kehadiran.');
      return;
    }

    await _refresh();
    if (!mounted) return;
    CustomSnackbar.showSuccess(context, 'Record kehadiran berhasil dihapus.');
  }

  Widget _buildReadOnlyOrganizerBody() {
    return ReadOnlyRecapBody(
      selectedReadOnlyEventId: _selectedReadOnlyEventId,
      events: _events,
      eventLabel: _eventLabel,
      onEventSelected: (value) {
        setState(() {
          _selectedReadOnlyEventId = value;
        });
      },
      readOnlyRecords: _readOnlyRecords,
      memberById: _memberById,
      formatDate: _formatDate,
      onRefresh: _refresh,
    );
  }

  Widget _buildCrudBody() {
    return CrudRecapBody(
      recapMode: _recapMode,
      onModeChanged: (value) {
        if (value == null) return;
        setState(() {
          _recapMode = value;
        });
      },
      modeLabel: _modeLabel,
      selectedMainEventId: _selectedMainEventId,
      onMainEventChanged: (value) {
        if (value == null) return;
        final subIds = _subEventIdsByMain[value] ?? const <String>[];
        setState(() {
          _selectedMainEventId = value;
          _selectedSubEventId = subIds.isEmpty ? null : subIds.first;
        });
      },
      selectedSubEventId: _selectedSubEventId,
      onSubEventChanged: (value) {
        setState(() {
          _selectedSubEventId = value;
        });
      },
      mainEvents: _mainEvents,
      subEventsForSelectedMain: _subEventsForSelectedMain,
      isMainEventCrudBlocked: _isMainEventCrudBlocked,
      filteredCrudRecords: _filteredCrudRecords,
      memberById: _memberById,
      eventLabel: _eventLabel,
      formatDate: _formatDate,
      onEditStatus: _editStatus,
      onDeleteRecord: _deleteRecord,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_canViewRecap) {
      return Scaffold(
        appBar: const GradientHeader(
          title: 'Rekap Kehadiran',
          subtitle: 'Akses Ditolak',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Anda tidak memiliki izin untuk melihat halaman ini.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: GradientHeader(
        title: 'Rekap Kehadiran',
        subtitle: _canCrud ? 'Kelola data absensi per event' : 'Mode read-only untuk organizer',
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
          ? RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(child: Text('Belum ada event/sub-event tersedia.')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _canCrud
                  ? _buildCrudBody()
                  : _buildReadOnlyOrganizerBody(),
            ),
    );
  }
}
