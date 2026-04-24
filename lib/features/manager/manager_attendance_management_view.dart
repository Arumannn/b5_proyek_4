import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../features/attendance/attendance_controller.dart';
import '../../features/attendance/scan_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';

enum RecapMode { byMainEvent, bySubEvent, aggregateByMainEvent, global }

class ManagerAttendanceManagementView extends StatefulWidget {
  const ManagerAttendanceManagementView({super.key});

  @override
  State<ManagerAttendanceManagementView> createState() =>
      _ManagerAttendanceManagementViewState();
}

class _ManagerAttendanceManagementViewState
    extends State<ManagerAttendanceManagementView> {
  bool _isLoading = true;
  List<EventModel> _events = const [];
  List<AttendanceRecord> _records = const [];
  Map<String, MemberModel> _memberById = const {};
  Map<String, EventModel> _eventById = const {};
  Map<String, List<String>> _subEventIdsByMain = const {};

  RecapMode _recapMode = RecapMode.byMainEvent;
  String? _selectedMainEventId;
  String? _selectedSubEventId;

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
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final records = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final members = HiveService.members.values.toList(growable: false);
    final map = <String, MemberModel>{for (final m in members) m.memberId: m};

    final eventById = <String, EventModel>{
      for (final e in events) e.eventId: e,
    };
    final mainEvents = events.where((e) => e.parentEventId == null).toList();

    final subEventIdsByMain = <String, List<String>>{};
    for (final main in mainEvents) {
      subEventIdsByMain[main.eventId] = <String>[];
    }
    for (final e in events) {
      final parentId = e.parentEventId;
      if (parentId != null && subEventIdsByMain.containsKey(parentId)) {
        subEventIdsByMain[parentId]!.add(e.eventId);
      }
    }

    String? selectedMain = _selectedMainEventId;
    if (selectedMain == null && mainEvents.isNotEmpty) {
      selectedMain = mainEvents.first.eventId;
    }
    if (selectedMain != null &&
        !mainEvents.any((e) => e.eventId == selectedMain)) {
      selectedMain = mainEvents.isNotEmpty ? mainEvents.first.eventId : null;
    }

    final subEvents = selectedMain == null
        ? const <String>[]
        : (subEventIdsByMain[selectedMain] ?? const <String>[]);

    String? selectedSub = _selectedSubEventId;
    if (selectedSub == null && subEvents.isNotEmpty) {
      selectedSub = subEvents.first;
    }
    if (selectedSub != null && !subEvents.contains(selectedSub)) {
      selectedSub = subEvents.isNotEmpty ? subEvents.first : null;
    }

    if (!mounted) return;
    setState(() {
      _events = events;
      _records = records;
      _memberById = map;
      _eventById = eventById;
      _subEventIdsByMain = subEventIdsByMain;
      _selectedMainEventId = selectedMain;
      _selectedSubEventId = selectedSub;
      _isLoading = false;
    });
  }

  List<EventModel> get _mainEvents {
    return _events
        .where((e) => e.parentEventId == null)
        .toList(growable: false);
  }

  List<EventModel> get _subEventsForSelectedMain {
    final mainId = _selectedMainEventId;
    if (mainId == null) return const [];
    final ids = _subEventIdsByMain[mainId] ?? const [];
    return ids
        .map((id) => _eventById[id])
        .whereType<EventModel>()
        .toList(growable: false);
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _eventLabel(String eventId) {
    final e = _eventById[eventId];
    if (e == null) return eventId;
    if (e.parentEventId == null) {
      return 'Event Utama - ${e.nama}';
    }
    final parentName = _eventById[e.parentEventId]?.nama ?? 'Unknown';
    return 'Sub-Event - $parentName / ${e.nama}';
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

  List<AttendanceRecord> get _filteredRecords {
    switch (_recapMode) {
      case RecapMode.byMainEvent:
        final mainId = _selectedMainEventId;
        if (mainId == null) return const [];
        return _records
            .where((r) => r.eventId == mainId)
            .toList(growable: false);
      case RecapMode.bySubEvent:
        final subId = _selectedSubEventId;
        if (subId == null) return const [];
        return _records
            .where((r) => r.eventId == subId)
            .toList(growable: false);
      case RecapMode.aggregateByMainEvent:
        final mainId = _selectedMainEventId;
        if (mainId == null) return const [];
        final allowedEventIds = <String>{
          mainId,
          ...?_subEventIdsByMain[mainId],
        };
        return _records
            .where((r) => allowedEventIds.contains(r.eventId))
            .toList(growable: false);
      case RecapMode.global:
        return List<AttendanceRecord>.from(_records, growable: false);
    }
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

  Future<void> _openScanQr() async {
    final targetEventId = _currentCrudEventId;
    if (targetEventId == null) {
      CustomSnackbar.showWarning(
        context,
        'Mode rekap saat ini tidak menunjuk 1 event spesifik. Gunakan mode Main Event atau Sub-Event untuk scan.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(eventId: targetEventId),
      ),
    );

    await _refresh();
  }

  Future<void> _addManualAttendance() async {
    final targetEventId = _currentCrudEventId;
    if (targetEventId == null) {
      CustomSnackbar.showWarning(
        context,
        'Tambah manual hanya tersedia pada mode Main Event atau Sub-Event.',
      );
      return;
    }

    String? selectedMemberId;
    String selectedStatus = 'Hadir';

    final members = _memberById.values.toList(growable: false)
      ..sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));

    if (members.isEmpty) {
      CustomSnackbar.showWarning(context, 'Belum ada anggota terdaftar.');
      return;
    }

    selectedMemberId = members.first.memberId;

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
                    value: selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Anggota',
                      border: OutlineInputBorder(),
                    ),
                    items: members
                        .map((m) {
                          return DropdownMenuItem<String>(
                            value: m.memberId,
                            child: Text('${m.nim} - ${m.nama}'),
                          );
                        })
                        .toList(growable: false),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMemberId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
                      DropdownMenuItem(
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

    if (saved != true || selectedMemberId == null) return;

    final ok = await AttendanceController.instance.addManualAttendance(
      eventId: targetEventId,
      memberId: selectedMemberId!,
      status: selectedStatus,
    );

    if (!mounted) return;

    if (!ok) {
      CustomSnackbar.showError(
        context,
        'Gagal menambah data. Pastikan tidak ada absensi ganda untuk user pada event ini.',
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
                value: selected,
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

    final managerId =
        AuthController.instance.currentUser.value?.memberId ?? 'manager';
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
        return AlertDialog(
          title: const Text('Hapus Kehadiran'),
          content: const Text('Yakin ingin menghapus record kehadiran ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Rekap Kehadiran (CRUD)'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? const Center(child: Text('Belum ada event/sub-event tersedia.'))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<RecapMode>(
                    value: _recapMode,
                    decoration: const InputDecoration(
                      labelText: 'Mode Rekap',
                      border: OutlineInputBorder(),
                    ),
                    items: RecapMode.values
                        .map((mode) {
                          return DropdownMenuItem<RecapMode>(
                            value: mode,
                            child: Text(_modeLabel(mode)),
                          );
                        })
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _recapMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_recapMode == RecapMode.byMainEvent ||
                      _recapMode == RecapMode.aggregateByMainEvent)
                    DropdownButtonFormField<String>(
                      value: _selectedMainEventId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Main Event',
                        border: OutlineInputBorder(),
                      ),
                      items: _mainEvents
                          .map((e) {
                            return DropdownMenuItem<String>(
                              value: e.eventId,
                              child: Text(e.nama),
                            );
                          })
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        final subIds =
                            _subEventIdsByMain[value] ?? const <String>[];
                        setState(() {
                          _selectedMainEventId = value;
                          _selectedSubEventId = subIds.isEmpty
                              ? null
                              : subIds.first;
                        });
                      },
                    ),
                  if (_recapMode == RecapMode.bySubEvent) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedMainEventId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Main Event',
                        border: OutlineInputBorder(),
                      ),
                      items: _mainEvents
                          .map((e) {
                            return DropdownMenuItem<String>(
                              value: e.eventId,
                              child: Text(e.nama),
                            );
                          })
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        final subIds =
                            _subEventIdsByMain[value] ?? const <String>[];
                        setState(() {
                          _selectedMainEventId = value;
                          _selectedSubEventId = subIds.isEmpty
                              ? null
                              : subIds.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedSubEventId,
                      decoration: const InputDecoration(
                        labelText: 'Pilih Sub-Event',
                        border: OutlineInputBorder(),
                      ),
                      items: _subEventsForSelectedMain
                          .map((e) {
                            return DropdownMenuItem<String>(
                              value: e.eventId,
                              child: Text(e.nama),
                            );
                          })
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubEventId = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Total record terfilter: ${_filteredRecords.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _openScanQr,
                        icon: const Icon(Icons.qr_code_scanner_outlined),
                        label: const Text('Scan QR'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addManualAttendance,
                        icon: const Icon(Icons.add_task_outlined),
                        label: const Text('Tambah Manual'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _filteredRecords.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada data kehadiran pada event ini.',
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('NIM')),
                                  DataColumn(label: Text('Nama')),
                                  DataColumn(label: Text('Event/Sub-event')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Timestamp')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: _filteredRecords
                                    .map((r) {
                                      final member = _memberById[r.memberId];
                                      final nim = member?.nim ?? r.memberId;
                                      final nama = member?.nama ?? '-';
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(nim)),
                                          DataCell(Text(nama)),
                                          DataCell(
                                            SizedBox(
                                              width: 220,
                                              child: Text(
                                                _eventLabel(r.eventId),
                                              ),
                                            ),
                                          ),
                                          DataCell(Text(r.status)),
                                          DataCell(
                                            Text(_formatDate(r.timestamp)),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  tooltip: 'Edit',
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                  ),
                                                  onPressed: () =>
                                                      _editStatus(r),
                                                ),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteRecord(r),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    })
                                    .toList(growable: false),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
