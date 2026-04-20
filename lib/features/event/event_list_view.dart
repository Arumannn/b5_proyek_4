import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../attendance/scan_screen.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbar.dart';
import 'event_controller.dart';
import 'event_form_view.dart';

/// Layar daftar event (Admin) — Implementasi penuh: Week 9
class EventListView extends StatefulWidget {
  const EventListView({super.key});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final EventController _controller = EventController.instance;

  @override
  void initState() {
    super.initState();
    _controller.loadEvents();
  }

  List<EventParentOption> get _parentOptions {
    return _controller
        .getRootEvents()
        .map((event) => EventParentOption(id: event.eventId, name: event.nama))
        .toList();
  }

  Future<void> _addEvent() async {
    final result = await Navigator.push<EventFormValue>(
      context,
      MaterialPageRoute<EventFormValue>(
        builder: (_) => EventFormView(
          title: 'Tambah Event',
          parentOptions: _parentOptions,
        ),
      ),
    );

    if (result == null) return;

    final success = await _controller.createEvent(
      nama: result.name,
      tanggal: result.date,
      parentEventId: result.isSubEvent ? result.parentId : null,
      jenis: 'Kegiatan',
    );

    if (!mounted) return;
    if (success) {
      CustomSnackbar.showSuccess(context, 'Event berhasil ditambahkan.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menambah event.',
      );
    }
  }

  Future<void> _editEvent(EventModel target) async {
    final isSubEvent = target.parentEventId != null;
    final result = await Navigator.push<EventFormValue>(
      context,
      MaterialPageRoute<EventFormValue>(
        builder: (_) => EventFormView(
          title: 'Edit Event',
          canChangeHierarchy: false,
          parentOptions: _parentOptions,
          initialValue: EventFormValue(
            name: target.nama,
            date: target.tanggal,
            isSubEvent: isSubEvent,
            parentId: target.parentEventId,
          ),
        ),
      ),
    );

    if (result == null) return;

    final success = await _controller.updateEvent(
      target.copyWith(
        nama: result.name,
        tanggal: result.date,
      ),
    );

    if (!mounted) return;
    if (success) {
      CustomSnackbar.showSuccess(context, 'Event berhasil diubah.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal mengubah event.',
      );
    }
  }

  Future<void> _deleteEvent(EventModel target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Event'),
          content: Text('Yakin ingin menghapus "${target.nama}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await _controller.deleteEvent(target.eventId);

    if (!mounted) return;
    if (success) {
      CustomSnackbar.showSuccess(context, 'Event berhasil dihapus.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menghapus event.',
      );
    }
  }

  Widget _buildSubEventItem(EventModel subEvent) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.subdirectory_arrow_right, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subEvent.nama,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(subEvent.tanggal),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ScanScreen(eventId: subEvent.eventId),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan'),
              ),
              OutlinedButton.icon(
                onPressed: () => _editEvent(subEvent),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteEvent(subEvent),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Hapus'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, {List<EventModel> subEvents = const []}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.nama, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(_formatDate(event.tanggal), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tambah Sub Event',
                  onPressed: () async {
                    final result = await Navigator.push<EventFormValue>(
                      context,
                      MaterialPageRoute<EventFormValue>(
                        builder: (_) => EventFormView(
                          title: 'Tambah Sub Event',
                          canChangeHierarchy: false,
                          parentOptions: _parentOptions,
                          initialValue: EventFormValue(
                            name: '',
                            date: DateTime.now(),
                            isSubEvent: true,
                            parentId: event.eventId,
                          ),
                        ),
                      ),
                    );

                    if (result == null) return;

                    final success = await _controller.createEvent(
                      nama: result.name,
                      tanggal: result.date,
                      parentEventId: event.eventId,
                      jenis: 'Kegiatan',
                    );

                    if (!mounted) return;
                    if (success) {
                      CustomSnackbar.showSuccess(context, 'Sub event berhasil ditambahkan.');
                    } else {
                      CustomSnackbar.showError(
                        context,
                        _controller.errorMessage.value ?? 'Gagal menambah sub event.',
                      );
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ScanScreen(eventId: event.eventId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Absensi'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editEvent(event),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _deleteEvent(event),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              ],
            ),
            if (subEvents.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                'Sub Event',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...subEvents.map(_buildSubEventItem),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Event'),
        actions: [
          IconButton(
            tooltip: 'Tambah Event',
            onPressed: _addEvent,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        tooltip: 'Tambah Event',
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) {
          return LoadingOverlay(
            isLoading: isLoading,
            child: ValueListenableBuilder<List<EventModel>>(
              valueListenable: _controller.events,
              builder: (context, events, _) {
                final rootEvents = events.where((e) => e.parentEventId == null).toList();
                rootEvents.sort((a, b) => a.tanggal.compareTo(b.tanggal));

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: _addEvent,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Event'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: rootEvents.isEmpty
                            ? const Center(
                                child: Text('Belum ada event. Tekan tombol + untuk menambah.'),
                              )
                            : ListView(
                                children: rootEvents
                                    .map(
                                      (event) {
                                        final children = events
                                            .where((e) => e.parentEventId == event.eventId)
                                            .toList()
                                          ..sort((a, b) => a.tanggal.compareTo(b.tanggal));

                                        return Column(
                                          children: [
                                            _buildEventCard(
                                              event,
                                              subEvents: children,
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                    .toList(),
                              ),
                      ),
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
