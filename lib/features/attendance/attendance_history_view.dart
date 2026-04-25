import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../auth/auth_controller.dart';

class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({super.key});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rows = const <Map<String, dynamic>>[];

  String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final user = AuthController.instance.currentUser.value;
    final eventById = <String, EventModel>{for (final e in HiveService.events.values) e.eventId: e};

    final rows = HiveService.attendance.values
        .where((r) => user != null && r.memberId == user.memberId)
        .map((r) {
          return <String, dynamic>{
            'eventName': eventById[r.eventId]?.nama ?? r.eventId,
            'status': r.status,
            'timestamp': r.timestamp,
          };
        })
        .toList(growable: false)
      ..sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    if (!mounted) return;
    setState(() {
      _rows = rows;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran Saya'),
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
          : _rows.isEmpty
              ? const Center(child: Text('Belum ada riwayat kehadiran.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.event_available_outlined),
                        title: Text(row['eventName'] as String),
                        subtitle: Text(_formatDateTime(row['timestamp'] as DateTime)),
                        trailing: Text(
                          row['status'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
