// ignore_for_file: deprecated_member_use

import 'package:b5_proyek_4/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';

class OrganizerAttendanceRecapView extends StatefulWidget {
  const OrganizerAttendanceRecapView({super.key});

  @override
  State<OrganizerAttendanceRecapView> createState() =>
      _OrganizerAttendanceRecapViewState();
}

class _OrganizerAttendanceRecapViewState
    extends State<OrganizerAttendanceRecapView> {
  bool _isLoading = true;
  List<EventModel> _allEvents = const [];
  List<AttendanceRecord> _allAttendance = const [];
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

    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    final attendance = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final members = HiveService.members.values.toList(growable: false);
    final map = <String, MemberModel>{for (final m in members) m.nim: m};

    String? selected = _selectedEventId;
    if (selected == null && events.isNotEmpty) {
      selected = events.first.eventId;
    }
    if (selected != null && !events.any((e) => e.eventId == selected)) {
      selected = events.isNotEmpty ? events.first.eventId : null;
    }

    if (!mounted) return;
    setState(() {
      _allEvents = events;
      _allAttendance = attendance;
      _memberById = map;
      _selectedEventId = selected;
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _eventLabel(EventModel event) {
    final parent = event.parentEventId;
    if (parent == null) {
      return 'Event Utama - ${event.nama}';
    }
    final parentName = _allEvents
        .where((e) => e.eventId == parent)
        .map((e) => e.nama)
        .cast<String?>()
        .firstWhere((_) => true, orElse: () => null);
    if (parentName == null) {
      return 'Sub-Event - ${event.nama}';
    }
    return 'Sub-Event - $parentName / ${event.nama}';
  }

  List<AttendanceRecord> get _rows {
    if (_selectedEventId == null) return const [];
    return _allAttendance
        .where((r) => r.eventId == _selectedEventId)
        .toList(growable: false);
  }

  Widget _buildTable() {
    final rows = _rows;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Belum ada data kehadiran pada event ini.')),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('NIM')),
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Status Kehadiran')),
          DataColumn(label: Text('Timestamp')),
        ],
        rows: rows
            .map((record) {
              final member = _memberById[record.nim];
              final nim = member?.nim ?? record.nim;
              final nama = member?.nama ?? '-';
              return DataRow(
                cells: [
                  DataCell(Text(nim)),
                  DataCell(Text(nama)),
                  DataCell(Text(record.status)),
                  DataCell(Text(_formatDateTime(record.timestamp))),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientHeader(
        title: 'Rekap Kehadiran',
        subtitle: 'Mode read-only untuk organizer',
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
          : _allEvents.isEmpty
          ? const Center(child: Text('Belum ada event tersedia.'))
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
                    items: _allEvents
                        .map((event) {
                          return DropdownMenuItem<String>(
                            value: event.eventId,
                            child: Text(_eventLabel(event)),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildTable(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
