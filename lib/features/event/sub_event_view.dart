import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart';

class SubEventView extends StatefulWidget {
  const SubEventView({super.key});

  @override
  State<SubEventView> createState() => _SubEventViewState();
}

class _SubEventViewState extends State<SubEventView> {
  final EventController _controller = EventController.instance;

  String get _role =>
      (AuthController.instance.currentUser.value?.role ??
              AppConstants.roleMember)
          .trim()
          .toLowerCase();

  bool get _canCrud =>
      _role == AppConstants.roleExecutive || _role == AppConstants.roleManager;

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _refresh() async {
    await _controller.loadEvents(force: true);
  }

  Future<void> _deleteSubEvent(EventModel subEvent) async {
    final ok = await _controller.deleteEvent(subEvent.eventId);
    if (!mounted) return;

    if (ok) {
      CustomSnackbar.showSuccess(context, 'Sub-event berhasil dihapus.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menghapus sub-event.',
      );
    }
  }

  Future<void> _editSubEvent(EventModel subEvent) async {
    final nameController = TextEditingController(text: subEvent.nama);
    final descController = TextEditingController(
      text: subEvent.deskripsi ?? '',
    );
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = subEvent.tanggal;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              setDialogState(() {
                selectedDate = picked;
              });
            }

            return AlertDialog(
              title: const Text('Edit Sub-Event'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Sub-Event',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama wajib diisi.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Tanggal Sub-Event'),
                        subtitle: Text(_formatDate(selectedDate)),
                        onTap: pickDate,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    final ok = await _controller.updateEvent(
      subEvent.copyWith(
        nama: nameController.text.trim(),
        tanggal: selectedDate,
        deskripsi: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
      ),
    );

    if (!mounted) return;

    if (ok) {
      CustomSnackbar.showSuccess(context, 'Sub-event berhasil diperbarui.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal memperbarui sub-event.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_canCrud ? 'Sub-Event (CRUD)' : 'Sub-Event (Read-Only)'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<EventModel>>(
        valueListenable: _controller.events,
        builder: (context, events, child) {
          final mains = _controller.getRootEvents();

          if (mains.isEmpty) {
            return const Center(child: Text('Belum ada main event tersedia.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: mains.length,
              itemBuilder: (context, index) {
                final mainEvent = mains[index];
                final subs = _controller.getSubEvents(mainEvent.eventId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(mainEvent.nama),
                    subtitle: Text(
                      'Main Event • ${_formatDate(mainEvent.tanggal)}',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    children: [
                      if (subs.isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Belum ada sub-event.'),
                        )
                      else
                        ...subs.map((sub) {
                          return Card(
                            margin: const EdgeInsets.only(top: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.subdirectory_arrow_right,
                              ),
                              title: Text(sub.nama),
                              subtitle: Text(
                                '${sub.jenis} • ${_formatDate(sub.tanggal)}',
                              ),
                              trailing: _canCrud
                                  ? Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed: () => _editSubEvent(sub),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () => _deleteSubEvent(sub),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
