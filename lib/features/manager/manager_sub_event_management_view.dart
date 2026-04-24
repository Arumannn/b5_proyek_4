import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_snackbar.dart';

class ManagerSubEventManagementView extends StatefulWidget {
  const ManagerSubEventManagementView({super.key});

  @override
  State<ManagerSubEventManagementView> createState() =>
      _ManagerSubEventManagementViewState();
}

class _ManagerSubEventManagementViewState
    extends State<ManagerSubEventManagementView> {
  bool _isLoading = true;
  List<EventModel> _allEvents = const [];

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

    if (!mounted) return;
    setState(() {
      _allEvents = events;
      _isLoading = false;
    });
  }

  List<EventModel> get _mainEvents {
    return _allEvents
        .where((e) => e.parentEventId == null)
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
        title: const Text('Pilih Main Event'),
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
                  const Text(
                    'Pilih Main Event (parent) untuk melihat dan mengelola Sub-Event (child).',
                  ),
                  if (_mainEvents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Belum ada Main Event. Sub-Event tidak dapat dibuat tanpa parent.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (_mainEvents.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada Main Event yang bisa dipilih.'),
                      ),
                    )
                  else
                    ..._mainEvents.map((mainEvent) {
                      final subCount = _allEvents
                          .where((e) => e.parentEventId == mainEvent.eventId)
                          .length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: Text(mainEvent.nama),
                          subtitle: Text(
                            '${_formatDate(mainEvent.tanggal)} • $subCount Sub-Event',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => _MainEventDetailSubEventView(
                                  mainEvent: mainEvent,
                                ),
                              ),
                            );

                            if (!mounted) return;
                            await _refresh();
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _MainEventDetailSubEventView extends StatefulWidget {
  const _MainEventDetailSubEventView({required this.mainEvent});

  final EventModel mainEvent;

  @override
  State<_MainEventDetailSubEventView> createState() =>
      _MainEventDetailSubEventViewState();
}

class _MainEventDetailSubEventViewState
    extends State<_MainEventDetailSubEventView> {
  bool _isLoading = true;
  List<EventModel> _subEvents = const [];

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    final subEvents =
        HiveService.events.values
            .where((e) => e.parentEventId == widget.mainEvent.eventId)
            .toList(growable: false)
          ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

    if (!mounted) return;
    setState(() {
      _subEvents = subEvents;
      _isLoading = false;
    });
  }

  Future<void> _showSubEventForm({EventModel? existing}) async {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: existing?.nama ?? '');
    final descController = TextEditingController(
      text: existing?.deskripsi ?? '',
    );

    DateTime selectedDate =
        existing?.tanggal ?? DateTime.now().add(const Duration(days: 1));
    String selectedJenis = existing?.jenis ?? AppConstants.eventTypes.first;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: selectedDate,
              );
              if (picked == null) return;
              setDialogState(() {
                selectedDate = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  selectedDate.hour,
                  selectedDate.minute,
                );
              });
            }

            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              final normalizedName = nameController.text.trim();
              final normalizedDesc = descController.text.trim();

              if (isEdit) {
                final updated = existing.copyWith(
                  nama: normalizedName,
                  tanggal: selectedDate,
                  parentEventId: widget.mainEvent.eventId,
                  jenis: selectedJenis,
                  deskripsi: normalizedDesc.isEmpty ? null : normalizedDesc,
                  isSynced: false,
                );
                await HiveService.events.put(updated.eventId, updated);
              } else {
                final created = EventModel(
                  eventId: DateTime.now().microsecondsSinceEpoch.toString(),
                  parentEventId: widget.mainEvent.eventId,
                  nama: normalizedName,
                  jenis: selectedJenis,
                  tanggal: selectedDate,
                  deskripsi: normalizedDesc.isEmpty ? null : normalizedDesc,
                  createdBy: 'manager',
                  isSynced: false,
                );
                await HiveService.events.put(created.eventId, created);
              }

              if (!context.mounted) return;
              Navigator.of(dialogContext).pop(true);
            }

            return AlertDialog(
              title: Text(isEdit ? 'Edit Sub-Event' : 'Tambah Sub-Event'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          initialValue: widget.mainEvent.nama,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Main Event (Parent)',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Sub-Event',
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama sub-event wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedJenis,
                          decoration: const InputDecoration(
                            labelText: 'Jenis',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: AppConstants.eventTypes
                              .map(
                                (jenis) => DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedJenis = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi (Opsional)',
                            prefixIcon: Icon(Icons.description_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Tanggal Sub-Event'),
                          subtitle: Text(_formatDate(selectedDate)),
                          trailing: const Icon(Icons.edit_calendar_outlined),
                          onTap: pickDate,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: submit,
                  child: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descController.dispose();

    if (saved == true) {
      await _refresh();
      if (!mounted) return;
      CustomSnackbar.showSuccess(
        context,
        isEdit
            ? 'Sub-event berhasil diperbarui.'
            : 'Sub-event berhasil ditambahkan.',
      );
    }
  }

  Future<void> _deleteSubEvent(EventModel target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Sub-Event'),
          content: Text('Yakin ingin menghapus sub-event "${target.nama}"?'),
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

    await HiveService.events.delete(target.eventId);
    await _refresh();
    if (!mounted) return;
    CustomSnackbar.showSuccess(context, 'Sub-event berhasil dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Event: ${widget.mainEvent.nama}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubEventForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Sub-Event'),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Main Event',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Nama: ${widget.mainEvent.nama}'),
                          Text(
                            'Tanggal: ${_formatDate(widget.mainEvent.tanggal)}',
                          ),
                          Text('Jenis: ${widget.mainEvent.jenis}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Daftar Sub-Event (child) dalam Main Event ini'),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _subEvents.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  'Belum ada sub-event pada main event ini.',
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nama Sub-Event')),
                                  DataColumn(label: Text('Tanggal')),
                                  DataColumn(label: Text('Deskripsi')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: _subEvents
                                    .map(
                                      (sub) => DataRow(
                                        cells: [
                                          DataCell(Text(sub.nama)),
                                          DataCell(
                                            Text(_formatDate(sub.tanggal)),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 220,
                                              child: Text(sub.deskripsi ?? '-'),
                                            ),
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
                                                      _showSubEventForm(
                                                        existing: sub,
                                                      ),
                                                ),
                                                IconButton(
                                                  tooltip: 'Hapus',
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () =>
                                                      _deleteSubEvent(sub),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
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
