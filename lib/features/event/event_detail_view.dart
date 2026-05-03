import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../widgets/gradient_header.dart';
import '../../models/member_model.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;
  const EventDetailView({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    final all = HiveService.attendance.values.where((r) => r.eventId == widget.event.eventId).toList(growable: false);
    all.sort((a,b) => b.timestamp.compareTo(a.timestamp));
    setState(() => _records = all);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year} • ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return const Color(0xFF22C55E); // Green 500
    if (s.contains('izin') || s.contains('sakit')) return const Color(0xFFF97316); // Orange 500
    if (s.contains('alpha') || s.contains('absent')) return const Color(0xFFEF4444); // Red 500
    return const Color(0xFF6B7280); // Gray 500
  }

  Color _statusBgColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return const Color(0xFFDCFCE7); // Green 100
    if (s.contains('izin') || s.contains('sakit')) return const Color(0xFFFFEDD5); // Orange 100
    if (s.contains('alpha') || s.contains('absent')) return const Color(0xFFFEE2E2); // Red 100
    return const Color(0xFFF3F4F6); // Gray 100
  }

  @override
  Widget build(BuildContext context) {
    final hadir = _records.where((r) => r.status.toLowerCase().contains('hadir')).length;
    final izin = _records.where((r) => r.status.toLowerCase().contains('izin') || r.status.toLowerCase().contains('sakit')).length;
    final alpha = _records.where((r) => r.status.toLowerCase().contains('alpha')).length;

    return Scaffold(
      appBar: GradientHeader(
        title: widget.event.nama,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.event.nama, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_formatDateTime(widget.event.tanggal)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _statTile('Hadir', hadir.toString(), Colors.green),
                      const SizedBox(width: 8),
                      _statTile('Izin', izin.toString(), Colors.orange),
                      const SizedBox(width: 8),
                      _statTile('Alpha', alpha.toString(), Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Daftar Kehadiran', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_records.isEmpty)
            const Card(
              child: Padding(padding: EdgeInsets.all(16), child: Text('Belum ada data kehadiran.')),
            )
          else
            ..._records.map((r) {
              final MemberModel? m = HiveService.members.get(r.nim);
              final name = m?.nama ?? r.nim;
              final nim = m?.nim ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF60A5FA),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text('NIM: $nim', style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(_formatDateTime(r.timestamp), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusBgColor(r.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          r.status,
                          style: TextStyle(
                            color: _statusColor(r.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}
