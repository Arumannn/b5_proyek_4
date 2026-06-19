import 'package:flutter/material.dart';
import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';

class AttendanceRecordsTable extends StatefulWidget {
  final List<AttendanceRecord> records;
  final Map<String, MemberModel> memberById;
  final String Function(String eventId)? eventLabelBuilder;
  final bool showEventColumn;
  final bool showActionColumn;
  final void Function(AttendanceRecord record)? onEdit;
  final void Function(AttendanceRecord record)? onDelete;
  final String emptyText;
  final bool enableFilters;
  final List<String> statuses;
  const AttendanceRecordsTable({
    super.key,
    required this.records,
    required this.memberById,
    this.eventLabelBuilder,
    this.showEventColumn = true,
    this.showActionColumn = false,
    this.onEdit,
    this.onDelete,
    this.emptyText = 'Belum ada data kehadiran.',
    this.enableFilters = false,
    this.statuses = const [
      'Hadir',
      'Terlambat',
      'Izin',
      'Sakit',
      'Alpha',
      'Ditolak',
    ],
  });
  @override
  State<AttendanceRecordsTable> createState() => _AttendanceRecordsTableState();
}

class _AttendanceRecordsTableState extends State<AttendanceRecordsTable> {
  String _selectedStatus = 'Semua';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isDateInRange(DateTime value) {
    final date = _dateOnly(value);
    if (_fromDate != null && date.isBefore(_dateOnly(_fromDate!))) {
      return false;
    }
    if (_toDate != null && date.isAfter(_dateOnly(_toDate!))) {
      return false;
    }
    return true;
  }

  List<AttendanceRecord> _filteredRecords() {
    return widget.records
        .where((record) {
          final passStatus =
              _selectedStatus == 'Semua' || record.status == _selectedStatus;
          final passDate = _isDateInRange(record.timestamp);
          return passStatus && passDate;
        })
        .toList(growable: false);
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final initial = _fromDate ?? _toDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = picked;
      if (_toDate != null && _toDate!.isBefore(picked)) {
        _toDate = picked;
      }
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final initial = _toDate ?? _fromDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _toDate = picked;
      if (_fromDate != null && _fromDate!.isAfter(picked)) {
        _fromDate = picked;
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'Semua';
      _fromDate = null;
      _toDate = null;
    });
  }

  Widget _buildFilterBar() {
    if (!widget.enableFilters) return const SizedBox.shrink();
    final statusItems = ['Semua', ...widget.statuses];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: statusItems
                  .map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickFromDate,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              _fromDate == null
                  ? 'Dari Tanggal'
                  : _formatDate(_fromDate!).split(' ').first,
            ),
          ),
          OutlinedButton.icon(
            onPressed: _pickToDate,
            icon: const Icon(Icons.event_available_outlined),
            label: Text(
              _toDate == null
                  ? 'Sampai Tanggal'
                  : _formatDate(_toDate!).split(' ').first,
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecords = _filteredRecords();
    final columns = <DataColumn>[
      const DataColumn(label: Text('NIM')),
      const DataColumn(label: Text('Nama')),
      if (widget.showEventColumn)
        const DataColumn(label: Text('Event/Sub-event')),
      const DataColumn(label: Text('Status')),
      const DataColumn(label: Text('Timestamp')),
      if (widget.showActionColumn) const DataColumn(label: Text('Action')),
    ];
    final rows = visibleRecords
        .map((record) {
          final member = widget.memberById[record.nim];
          final nim = member?.nim ?? record.nim;
          final nama = member?.nama ?? '-';
          final cells = <DataCell>[
            DataCell(Text(nim)),
            DataCell(Text(nama)),
            if (widget.showEventColumn)
              DataCell(
                SizedBox(
                  width: 220,
                  child: Text(
                    widget.eventLabelBuilder?.call(record.eventId) ??
                        record.eventId,
                  ),
                ),
              ),
            DataCell(Text(record.status)),
            DataCell(Text(_formatDate(record.timestamp))),
            if (widget.showActionColumn)
              DataCell(
                Row(
                  children: [
                    if (widget.onEdit != null)
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => widget.onEdit!(record),
                      ),
                    if (widget.onDelete != null)
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => widget.onDelete!(record),
                      ),
                  ],
                ),
              ),
          ];
          return DataRow(cells: cells);
        })
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        if (visibleRecords.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(widget.emptyText)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: columns, rows: rows),
          ),
      ],
    );
  }
}
