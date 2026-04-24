import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';

class OrganizerEventOverviewView extends StatefulWidget {
  const OrganizerEventOverviewView({super.key});

  @override
  State<OrganizerEventOverviewView> createState() =>
      _OrganizerEventOverviewViewState();
}

class _OrganizerEventOverviewViewState
    extends State<OrganizerEventOverviewView> {
  bool _isLoading = true;
  List<EventModel> _allEvents = const [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    final events = HiveService.events.values.toList(growable: false)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (!mounted) return;
    setState(() {
      _allEvents = events;
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

  List<EventModel> get _mainEvents {
    return _allEvents
        .where((e) => e.parentEventId == null)
        .toList(growable: false);
  }

  List<EventModel> _subEventsOf(String parentId) {
    return _allEvents
        .where((e) => e.parentEventId == parentId)
        .toList(growable: false)
      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
  }

  void _showEventDetail(EventModel event, {bool isSubEvent = false}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isSubEvent ? 'Detail Sub-Event' : 'Detail Event Utama'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Nama', event.nama),
                _detailRow('Jenis', event.jenis),
                _detailRow('Tanggal', _formatDateTime(event.tanggal)),
                _detailRow(
                  'Deskripsi',
                  event.deskripsi?.trim().isNotEmpty == true
                      ? event.deskripsi!
                      : '-',
                ),
                _detailRow(
                  'Target Peserta',
                  event.targetPeserta.isEmpty
                      ? 'Semua Anggota'
                      : event.targetPeserta.join(', '),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mains = _mainEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event dan Sub-Event'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : mains.isEmpty
          ? const Center(child: Text('Belum ada event tersedia.'))
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mains.length,
                itemBuilder: (context, index) {
                  final mainEvent = mains[index];
                  final subEvents = _subEventsOf(mainEvent.eventId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(mainEvent.nama),
                      subtitle: Text(
                        '${mainEvent.jenis} • ${_formatDateTime(mainEvent.tanggal)}',
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _showEventDetail(mainEvent),
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Lihat Detail Event Utama'),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (subEvents.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Belum ada sub-event.'),
                          )
                        else
                          ...subEvents.map((subEvent) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                              ),
                              title: Text(subEvent.nama),
                              subtitle: Text(
                                '${subEvent.jenis} • ${_formatDateTime(subEvent.tanggal)}',
                              ),
                              onTap: () =>
                                  _showEventDetail(subEvent, isSubEvent: true),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
