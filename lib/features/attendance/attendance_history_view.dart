
import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../../features/event/event_controller.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../attendance/widgets/attendance_records_table.dart';

/// Riwayat kehadiran pribadi Member — Implementasi penuh: Week 12
class AttendanceHistoryView extends StatefulWidget {
  final String memberId;
  final String nim;
  const AttendanceHistoryView({
    super.key,
    required this.memberId,
    required this.nim,
  });

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  bool _isLoading = true;
  List<AttendanceRecord> _records = const [];
  Map<String, EventModel> _eventById = const {};
  Map<String, MemberModel> _memberById = const {};

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

    final events = HiveService.events.values.toList(growable: false);
    final members = HiveService.members.values.toList(growable: false);
    final allRecords = HiveService.attendance.values.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final filtered = allRecords
        .where(
          (r) =>
              r.memberId.trim() == widget.memberId.trim() ||
              r.memberId.trim() == widget.nim.trim(),
        )
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      _records = filtered;
      _eventById = {for (final e in events) e.eventId: e};
      _memberById = {for (final m in members) m.memberId: m};
      _isLoading = false;
    });
  }
  String _eventLabel(String eventId) {
    final event = _eventById[eventId];
    if (event == null) return eventId;
    if (event.parentEventId == null) {
      return 'Event Utama - ${event.nama}';
    }
    final parent = _eventById[event.parentEventId!];
    if (parent == null) {
      return 'Sub-Event - ${event.nama}';
    }
    return 'Sub-Event - ${parent.nama} / ${event.nama}';
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
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
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AttendanceRecordsTable(
                        records: _records,
                        memberById: _memberById,
                        eventLabelBuilder: _eventLabel,
                        showEventColumn: true,
                        showActionColumn: false,
                        enableFilters: true,
                        emptyText: 'Belum ada riwayat kehadiran Anda.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
