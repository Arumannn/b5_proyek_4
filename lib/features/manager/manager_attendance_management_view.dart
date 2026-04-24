import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../features/attendance/attendance_controller.dart';
import '../../features/attendance/scan_screen.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/event/event_controller.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';

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
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    await AttendanceController.instance.loadData();
    await EventController.instance.loadEvents(force: true);

    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final records = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final members = HiveService.members.values.toList(growable: false);
    final map = <String, MemberModel>{for (final m in members) m.memberId: m};

    String? selected = _selectedEventId;
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

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
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

  List<AttendanceRecord> get _filteredRecords {
    if (_selectedEventId == null) return const [];
    return _records
        .where((r) => r.eventId == _selectedEventId)
        .toList(growable: false);
  }

  Future<void> _openScanQr() async {
    if (_selectedEventId == null) {
      CustomSnackbar.showWarning(context, 'Pilih event terlebih dahulu.');
      return;
    }

    final hasSubEvents = _events.any((e) => e.parentEventId == _selectedEventId);
    if (hasSubEvents) {
      CustomSnackbar.showWarning(context, 'Pilih sub-event untuk absensi karena event utama ini memiliki sub-event.');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(eventId: _selectedEventId!),
      ),
    );

    await _refresh();
  }

  Future<void> _addManualAttendance() async {
    if (_selectedEventId == null) {
      CustomSnackbar.showWarning(context, 'Pilih event terlebih dahulu.');
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
      eventId: _selectedEventId!,
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
                  DropdownButtonFormField<String>(
                    value: _selectedEventId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Event / Sub-Event',
                      border: OutlineInputBorder(),
                    ),
                    items: _events
                        .map((e) {
                          return DropdownMenuItem<String>(
                            value: e.eventId,
                            child: Text(_eventLabel(e.eventId)),
                          );
                        })
                        .toList(growable: false),
                    onChanged: (value) {
                      setState(() {
                        _selectedEventId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
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
