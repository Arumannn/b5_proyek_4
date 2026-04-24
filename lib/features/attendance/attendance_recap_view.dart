import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';

class AttendanceRecapView extends StatefulWidget {
  final String? initialEventId;
  const AttendanceRecapView({super.key, this.initialEventId});

  @override
  State<AttendanceRecapView> createState() => _AttendanceRecapViewState();
}

class _AttendanceRecapViewState extends State<AttendanceRecapView> {
  bool _isLoading = true;
  List<EventModel> _events = const [];
  List<AttendanceRecord> _records = const [];
  Map<String, MemberModel> _memberById = const {};
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    _refresh();
  }

  void _refresh() {
    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _events = events;
      _records = records;
      _memberById = map;
      _selectedEventId = selected;
      _isLoading = false;
    });
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

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Kehadiran'),
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
              ? const Center(child: Text('Belum ada event tersedia.'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedEventId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Event / Sub-Event',
                          border: OutlineInputBorder(),
                        ),
                        items: _events.map((e) {
                          return DropdownMenuItem<String>(
                            value: e.eventId,
                            child: Text(_eventLabel(e.eventId)),
                          );
                        }).toList(growable: false),
                        onChanged: (value) {
                          setState(() {
                            _selectedEventId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Rekap Absensi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          child: _filteredRecords.isEmpty
                              ? const Center(
                                  child: Text('Belum ada data kehadiran pada event ini.'),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('NIM')),
                                        DataColumn(label: Text('Nama')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Timestamp')),
                                      ],
                                      rows: _filteredRecords.map((r) {
                                        final member = _memberById[r.memberId];
                                        final nim = member?.nim ?? r.memberId;
                                        final nama = member?.nama ?? '-';
                                        return DataRow(
                                          cells: [
                                            DataCell(Text(nim)),
                                            DataCell(Text(nama)),
                                            DataCell(Text(r.status)),
                                            DataCell(Text(_formatDate(r.timestamp))),
                                          ],
                                        );
                                      }).toList(growable: false),
                                    ),
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
