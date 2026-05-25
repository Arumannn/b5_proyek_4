import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/sectioned_list_body.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart';
import 'event_permission.dart';

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

  bool get _canCreateSubEvent => EventPermission.canCreateSubEvent(_role);
  bool get _canUpdateSubEvent => EventPermission.canUpdateSubEvent(_role);
  bool get _canDeleteSubEvent => EventPermission.canDeleteSubEvent(_role);
  bool get _canManageSubEvent =>
      _canCreateSubEvent || _canUpdateSubEvent || _canDeleteSubEvent;

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _refresh() async {
    await _controller.refreshEvents(cloudSync: true);
  }

  Future<void> _deleteSubEvent(EventModel subEvent) async {
    if (!_canDeleteSubEvent) {
      CustomSnackbar.showError(
          context, 'Anda tidak memiliki izin menghapus sub-event.');
      return;
    }

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
    if (!_canUpdateSubEvent) {
      CustomSnackbar.showError(
          context, 'Anda tidak memiliki izin mengubah sub-event.');
      return;
    }

    final nameController = TextEditingController(text: subEvent.nama);
    final descController = TextEditingController(
      text: subEvent.deskripsi ?? '',
    );
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = subEvent.tanggalMulai;

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
        tanggalMulai: selectedDate,
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

  Color _getJenisColor(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'rapat':
        return Colors.blue;
      case 'acara':
        return Colors.purple;
      case 'kegiatan':
        return Colors.green;
      case 'lainnya':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getJenisTintColor(String jenis) {
    final base = _getJenisColor(jenis);
    return base.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      appBar: GradientHeader(
        title: _canManageSubEvent ? 'Sub-Event (CRUD)' : 'Sub-Event (Read-Only)',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, color: Colors.white),
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

          return SectionedListBody(
            header: const SizedBox.shrink(),
            searchBar: const SizedBox.shrink(),
            filterArea: const SizedBox.shrink(),
            emptyState: const SizedBox.shrink(),
            onRefresh: _refresh,
            listBuilder: (context) => ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: mains.length,
              itemBuilder: (context, index) {
                final mainEvent = mains[index];
                final subs = _controller.getSubEvents(mainEvent.eventId);
                return _buildMainEventCard(mainEvent, subs);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainEventCard(EventModel mainEvent, List<EventModel> subs) {
    final jenisColor = _getJenisColor(mainEvent.jenis);
    final jenisTint = _getJenisTintColor(mainEvent.jenis);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Event Header Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: jenisColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Jenis badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: jenisTint,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          mainEvent.jenis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: jenisColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        mainEvent.nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(mainEvent.tanggalMulai),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Sub-events list
          if (subs.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Sub-Events (${subs.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  ...subs.asMap().entries.map((entry) {
                    final sub = entry.value;
                    return _buildSubEventItem(sub, jenisColor);
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubEventItem(EventModel sub, Color parentJenisColor) {
    final subJenisColor = _getJenisColor(sub.jenis);
    final subJenisTint = _getJenisTintColor(sub.jenis);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.subdirectory_arrow_right_outlined,
            size: 18,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: subJenisTint,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        sub.jenis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subJenisColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.nama,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(sub.tanggalMulai),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_canManageSubEvent)
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Edit',
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                      ),
                      onPressed: () => _editSubEvent(sub),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Hapus',
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteSubEvent(sub),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
