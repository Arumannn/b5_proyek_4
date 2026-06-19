import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/table_page_body.dart';

class ReadOnlyRecapBody extends StatelessWidget {
  final String? selectedReadOnlyEventId;
  final List<EventModel> events;
  final String Function(String) eventLabel;
  final ValueChanged<String?> onEventSelected;
  final List<AttendanceRecord> readOnlyRecords;
  final Map<String, MemberModel> memberById;
  final String Function(DateTime) formatDate;
  final VoidCallback onRefresh;

  const ReadOnlyRecapBody({
    super.key,
    required this.selectedReadOnlyEventId,
    required this.events,
    required this.eventLabel,
    required this.onEventSelected,
    required this.readOnlyRecords,
    required this.memberById,
    required this.formatDate,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return TablePageBody(
      header: const SizedBox.shrink(),
      summaryArea: const Text(
        'Pilih event atau sub-event untuk melihat rekap kehadiran terbaru.',
      ),
      filterArea: DropdownButtonFormField<String>(
        initialValue: selectedReadOnlyEventId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Pilih Event / Sub-Event',
          border: OutlineInputBorder(),
        ),
        items: events
            .map(
              (event) => DropdownMenuItem<String>(
                value: event.eventId,
                child: Text(
                  eventLabel(event.eventId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onEventSelected,
      ),
      tableBuilder: (context) => readOnlyRecords.isEmpty
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
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Timestamp')),
                ],
                rows: readOnlyRecords
                    .map((r) {
                      final member = memberById[r.nim];
                      return DataRow(
                        cells: [
                          DataCell(Text(member?.nim ?? r.nim)),
                          DataCell(Text(member?.nama ?? '-')),
                          DataCell(Text(r.status)),
                          DataCell(Text(formatDate(r.timestamp))),
                        ],
                      );
                    })
                    .toList(growable: false),
              ),
            ),
      emptyState: const SizedBox.shrink(),
      onRefresh: () async => onRefresh(),
    );
  }
}
