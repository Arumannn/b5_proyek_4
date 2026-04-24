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

  List<EventModel> get _subEvents {
    return _allEvents
        .where((e) => e.parentEventId != null)
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

  String _mainEventName(String? parentId) {
    if (parentId == null) return '-';
    for (final e in _mainEvents) {
      if (e.eventId == parentId) return e.nama;
    }
    return '-';
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

    String? selectedParentId = existing?.parentEventId;
    if (selectedParentId == null && _mainEvents.isNotEmpty) {
      selectedParentId = _mainEvents.first.eventId;
    }

    if (_mainEvents.isEmpty) {
      if (!mounted) return;
      CustomSnackbar.showWarning(
        context,
        'Belum ada event utama. Buat event utama terlebih dahulu oleh Admin.',
      );
      return;
    }

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

            Future<void> pickTime() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: selectedDate.hour,
                  minute: selectedDate.minute,
                ),
              );
              if (picked == null) return;
              setDialogState(() {
                selectedDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  picked.hour,
                  picked.minute,
                );
              });
            }

            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              if (selectedParentId == null) return;

              final nowIso = DateTime.now();
              final normalizedName = nameController.text.trim();
              final normalizedDesc = descController.text.trim();

              if (isEdit) {
                final updated = existing.copyWith(
                  nama: normalizedName,
                  tanggal: selectedDate,
                  parentEventId: selectedParentId,
                  jenis: selectedJenis,
                  deskripsi: normalizedDesc.isEmpty ? null : normalizedDesc,
                  isSynced: false,
                );
                await HiveService.events.put(updated.eventId, updated);
              } else {
                final created = EventModel(
                  eventId: nowIso.microsecondsSinceEpoch.toString(),
                  parentEventId: selectedParentId,
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
                          value: selectedParentId,
                          decoration: const InputDecoration(
                            labelText: 'Event Utama',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                          ),
                          items: _mainEvents
                              .map((e) {
                                return DropdownMenuItem<String>(
                                  value: e.eventId,
                                  child: Text(e.nama),
                                );
                              })
                              .toList(growable: false),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedParentId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Event utama wajib dipilih.';
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
                              .map((jenis) {
                                return DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                );
                              })
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
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_outlined),
                          title: const Text('Waktu Dimulai'),
                          subtitle: Text(
                            '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: pickTime,
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
        title: const Text('Kelola Sub-Event (CRUD)'),
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
                  const Text(
                    'Manager memiliki akses penuh CRUD khusus untuk sub-event.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _subEvents.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Belum ada sub-event.'),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Nama Sub-Event')),
                                  DataColumn(label: Text('Tanggal')),
                                  DataColumn(label: Text('Event Utama')),
                                  DataColumn(label: Text('Deskripsi')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: _subEvents
                                    .map((sub) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(sub.nama)),
                                          DataCell(
                                            Text(_formatDate(sub.tanggal)),
                                          ),
                                          DataCell(
                                            Text(
                                              _mainEventName(sub.parentEventId),
                                            ),
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
                                      );
                                    })
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
