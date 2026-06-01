import 'package:flutter/material.dart';

import '../../../models/attendance_record.dart';
import '../../../models/event_model.dart';
import '../../../models/member_model.dart';
import '../attendance_recap_view.dart'; // To get RecapMode enum

class CrudRecapBody extends StatelessWidget {
  final RecapMode recapMode;
  final ValueChanged<RecapMode?> onModeChanged;
  final String Function(RecapMode) modeLabel;
  final String? selectedMainEventId;
  final ValueChanged<String?> onMainEventChanged;
  final String? selectedSubEventId;
  final ValueChanged<String?> onSubEventChanged;
  final List<EventModel> mainEvents;
  final List<EventModel> subEventsForSelectedMain;
  final bool isMainEventCrudBlocked;
  final List<AttendanceRecord> filteredCrudRecords;
  final Map<String, MemberModel> memberById;
  final String Function(String) eventLabel;
  final String Function(DateTime) formatDate;
  final void Function(AttendanceRecord) onEditStatus;
  final void Function(AttendanceRecord) onDeleteRecord;

  const CrudRecapBody({
    super.key,
    required this.recapMode,
    required this.onModeChanged,
    required this.modeLabel,
    required this.selectedMainEventId,
    required this.onMainEventChanged,
    required this.selectedSubEventId,
    required this.onSubEventChanged,
    required this.mainEvents,
    required this.subEventsForSelectedMain,
    required this.isMainEventCrudBlocked,
    required this.filteredCrudRecords,
    required this.memberById,
    required this.eventLabel,
    required this.formatDate,
    required this.onEditStatus,
    required this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<RecapMode>(
          initialValue: recapMode,
          decoration: const InputDecoration(
            labelText: 'Mode Rekap',
            border: OutlineInputBorder(),
          ),
          items: RecapMode.values
              .map(
                (mode) => DropdownMenuItem<RecapMode>(
                  value: mode,
                  child: Text(modeLabel(mode)),
                ),
              )
              .toList(growable: false),
          onChanged: onModeChanged,
        ),
        const SizedBox(height: 12),
        if (recapMode == RecapMode.byMainEvent ||
            recapMode == RecapMode.aggregateByMainEvent)
          DropdownButtonFormField<String>(
            initialValue: selectedMainEventId,
            decoration: const InputDecoration(
              labelText: 'Pilih Main Event',
              border: OutlineInputBorder(),
            ),
            items: mainEvents
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.eventId,
                    child: Text(e.nama),
                  ),
                )
                .toList(growable: false),
            onChanged: onMainEventChanged,
          ),
        if (recapMode == RecapMode.bySubEvent) ...[
          DropdownButtonFormField<String>(
            initialValue: selectedMainEventId,
            decoration: const InputDecoration(
              labelText: 'Pilih Main Event',
              border: OutlineInputBorder(),
            ),
            items: mainEvents
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.eventId,
                    child: Text(e.nama),
                  ),
                )
                .toList(growable: false),
            onChanged: onMainEventChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedSubEventId,
            decoration: const InputDecoration(
              labelText: 'Pilih Sub-Event',
              border: OutlineInputBorder(),
            ),
            items: subEventsForSelectedMain
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.eventId,
                    child: Text(e.nama),
                  ),
                )
                .toList(growable: false),
            onChanged: onSubEventChanged,
          ),
        ],
        const SizedBox(height: 12),
        if (isMainEventCrudBlocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Text(
              'Main event ini memiliki sub-event, sehingga absensi hanya boleh dicatat pada sub-event.',
            ),
          ),
        const SizedBox(height: 12),
        Text('Total record terfilter: ${filteredCrudRecords.length}'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: filteredCrudRecords.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Belum ada data kehadiran pada event ini.'),
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
                      rows: filteredCrudRecords
                          .map((r) {
                            final member = memberById[r.nim];
                            return DataRow(
                              cells: [
                                DataCell(Text(member?.nim ?? r.nim)),
                                DataCell(Text(member?.nama ?? '-')),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Text(eventLabel(r.eventId)),
                                  ),
                                ),
                                DataCell(Text(r.status)),
                                DataCell(Text(formatDate(r.timestamp))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => onEditStatus(r),
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus',
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () => onDeleteRecord(r),
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
    );
  }
}
