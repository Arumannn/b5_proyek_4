// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/gradient_header.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart';
import 'event_permission.dart';
import 'event_detail_view.dart';

class EventView extends StatefulWidget {
  const EventView({super.key});

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  final EventController _controller = EventController.instance;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedState = <String, bool>{};

  String get _role =>
      (AuthController.instance.currentUser.value?.role ??
              AppConstants.roleMember)
          .trim()
          .toLowerCase();

  bool get _canCreateMainEvent => EventPermission.canCreateMainEvent(_role); // RBAC: Main event CREATE hanya Executive.
  bool get _canUpdateMainEvent => EventPermission.canUpdateMainEvent(_role); // RBAC: Main event UPDATE hanya Executive.
  bool get _canDeleteMainEvent => EventPermission.canDeleteMainEvent(_role); // RBAC: Main event DELETE hanya Executive.
  bool get _canCreateSubEvent => EventPermission.canCreateSubEvent(_role); // RBAC: Sub-event CRUD untuk Executive/Manager.
  bool get _canUpdateSubEvent => EventPermission.canUpdateSubEvent(_role); // RBAC: Sub-event CRUD untuk Executive/Manager.
  bool get _canDeleteSubEvent => EventPermission.canDeleteSubEvent(_role); // RBAC: Sub-event CRUD untuk Executive/Manager.
  bool get _hasAnyCrudAccess => _canCreateMainEvent || _canCreateSubEvent; // RBAC: Penanda UI jika ada hak tulis di salah satu scope.

  @override
  void initState() {
    super.initState();
    _controller.loadEvents();
    _searchController.addListener(() {
      _controller.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EventModel> get _parentOptions => _controller.getRootEvents();

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Color _chipColor(String jenis) {
    switch (jenis) {
      case 'Rapat':
        return Colors.blue;
      case 'Acara':
        return Colors.purple;
      case 'Kegiatan':
        return Colors.green;
      case 'Lainnya':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<AttendanceRecord> _attendanceForEvent(String eventId) {
    return HiveService.attendance.values
        .where((record) => record.eventId == eventId)
        .toList(growable: false);
  }

  String _eventStatusLabel(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? 'Selesai' : 'Berlangsung';
  }

  Color _eventStatusColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFF22C55E) : const Color(0xFF2563EB);
  }

  Color _eventStatusBgColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggalMulai.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
  }

  String _eventLocation(EventModel event) {
    final lokasiValue = event.lokasi?.trim();
    if (lokasiValue != null && lokasiValue.isNotEmpty) return lokasiValue;
    return 'Lokasi belum diatur';
  }

  int _targetCount(EventModel event, int presentCount) {
    final target = event.targetPeserta.length;
    if (target > 0) return target;
    return presentCount > 0 ? presentCount : 1;
  }

  Future<void> _showJenisFilter() async {
    final available =
        _controller.events.value.map((e) => e.jenis).toSet().toList()..sort();

    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Filter Jenis Event'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: const Text('Semua Jenis'),
            ),
            const Divider(),
            ...available.map((jenis) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, jenis),
                child: Text(jenis),
              );
            }),
          ],
        );
      },
    );

    _controller.setJenisFilter(selected);
  }

  Future<void> _showDateRangeFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
    );

    if (picked != null) {
      _controller.setDateRangeFilter(picked);
    }
  }

  Future<void> _addOrEditEvent({
    EventModel? existing,
    String? forcedParentId,
  }) async {
    final isCreate = existing == null; // RBAC: Bedakan aksi CREATE vs UPDATE untuk validasi izin.
    final isSubEvent = // RBAC: Sub-event jika forced parent ada atau target existing punya parent.
        forcedParentId != null || (existing?.parentEventId != null);

    if (isCreate && !isSubEvent && !_canCreateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat main event.'); // RBAC: Cegah CREATE main event tanpa izin.
      return;
    }
    if (isCreate && isSubEvent && !_canCreateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat sub-event.'); // RBAC: Cegah CREATE sub-event tanpa izin.
      return;
    }
    if (!isCreate && !isSubEvent && !_canUpdateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah main event.'); // RBAC: Cegah UPDATE main event tanpa izin.
      return;
    }
    if (!isCreate && isSubEvent && !_canUpdateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah sub-event.'); // RBAC: Cegah UPDATE sub-event tanpa izin.
      return;
    }

    final form = await _showEventFormDialog(
      title: existing == null
          ? (forcedParentId == null ? 'Tambah Event' : 'Tambah Sub-Event')
          : 'Edit Event',
      initial: existing,
      forcedParentId: forcedParentId,
    );

    if (form == null) return;

    final ok = existing == null
        ? await _controller.createEvent(
            nama: form.name,
            tanggalMulai: form.date,
            parentEventId: form.parentEventId,
            jenis: form.jenis,
            lokasi: form.lokasi,
            deskripsi: form.deskripsi,
            targetPeserta: form.targetPeserta,
          )
        : await _controller.updateEvent(
            existing.copyWith(
              nama: form.name,
              tanggalMulai: form.date,
              parentEventId: form.parentEventId,
              jenis: form.jenis,
              lokasi: form.lokasi,
              deskripsi: form.deskripsi,
              targetPeserta: form.targetPeserta,
            ),
          );

    if (!mounted) return;

    if (!ok) {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menyimpan event.',
      );
      return;
    }

    if (forcedParentId != null) {
      setState(() {
        _expandedState[forcedParentId] = true;
      });
    }

    CustomSnackbar.showSuccess(
      context,
      existing == null
          ? 'Event berhasil ditambahkan.'
          : 'Event berhasil diubah.',
    );
  }

  Future<void> _deleteEvent(EventModel target) async {
    final isSubEvent = target.parentEventId != null; // RBAC: Izin DELETE ditentukan dari hirarki event.
    if (!isSubEvent && !_canDeleteMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus main event.'); // RBAC: Cegah DELETE main event tanpa izin.
      return;
    }
    if (isSubEvent && !_canDeleteSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus sub-event.'); // RBAC: Cegah DELETE sub-event tanpa izin.
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Event'),
          content: Text('Yakin ingin menghapus "${target.nama}"?'),
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

    final ok = await _controller.deleteEvent(target.eventId);

    if (!mounted) return;
    if (ok) {
      CustomSnackbar.showSuccess(context, 'Event berhasil dihapus.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menghapus event.',
      );
    }
  }

  Future<_EventFormData?> _showEventFormDialog({
    required String title,
    EventModel? initial,
    String? forcedParentId,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initial?.nama ?? '');
    final lokasiController = TextEditingController(text: initial?.lokasi ?? '');
    final descController = TextEditingController(
      text: initial?.deskripsi ?? '',
    );

    DateTime selectedDate = initial?.tanggalMulai ?? DateTime.now();
    String selectedJenis = initial?.jenis ?? AppConstants.eventTypes.first;
    bool isSubEvent = forcedParentId != null || initial?.parentEventId != null;
    String? parentId = forcedParentId ?? initial?.parentEventId;
    Set<String> targetDivisi = Set<String>.from(
      initial?.targetPeserta ?? const [],
    );

    final allDbu = AppConstants.allDbuOptions;

    final result = await showDialog<_EventFormData>(
      context: context,
      barrierDismissible: false,
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
              title: Text(title),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Event',
                            prefixIcon: Icon(Icons.event_note_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama event wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedJenis,
                          decoration: const InputDecoration(
                            labelText: 'Jenis Event',
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('Tanggal'),
                          subtitle: Text(_formatDate(selectedDate)),
                          trailing: const Icon(Icons.edit_calendar_outlined),
                          onTap: pickDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: lokasiController,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi (Opsional)',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                        if (forcedParentId == null) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: isSubEvent,
                            title: const Text('Jadikan Sub-Event'),
                            onChanged: (value) {
                              setDialogState(() {
                                isSubEvent = value;
                                if (!value) parentId = null;
                              });
                            },
                          ),
                        ],
                        if (isSubEvent) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: parentId,
                            decoration: const InputDecoration(
                              labelText: 'Main Event (Parent)',
                              prefixIcon: Icon(Icons.account_tree_outlined),
                            ),
                            items: _parentOptions
                                .where(
                                  (e) =>
                                      initial == null ||
                                      e.eventId != initial.eventId,
                                )
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e.eventId,
                                    child: Text(e.nama),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: forcedParentId != null
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      parentId = value;
                                    });
                                  },
                            validator: (value) {
                              if (!isSubEvent) return null;
                              if (value == null || value.isEmpty) {
                                return 'Pilih parent event.';
                              }
                              return null;
                            },
                          ),
                        ],
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Target Divisi (Opsional)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allDbu
                              .map((divisi) {
                                final selected = targetDivisi.contains(divisi);
                                return FilterChip(
                                  label: Text(divisi),
                                  selected: selected,
                                  onSelected: (value) {
                                    setDialogState(() {
                                      if (value) {
                                        targetDivisi.add(divisi);
                                      } else {
                                        targetDivisi.remove(divisi);
                                      }
                                    });
                                  },
                                );
                              })
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) return;
                    Navigator.of(dialogContext).pop(
                      _EventFormData(
                        name: nameController.text.trim(),
                        date: selectedDate,
                        jenis: selectedJenis,
                        parentEventId: isSubEvent ? parentId : null,
                                lokasi: lokasiController.text.trim().isEmpty
                                    ? null
                                    : lokasiController.text.trim(),
                        deskripsi: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        targetPeserta: targetDivisi.toList(growable: false),
                      ),
                    );
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    lokasiController.dispose();
    descController.dispose();
    return result;
  }

  Widget _buildActionButtons(EventModel event, {String? forcedParentId}) {
    final isSubEvent = event.parentEventId != null; // RBAC: Tentukan paket izin per scope.
    final hasSubEvents = !isSubEvent && _controller.getSubEvents(event.eventId).isNotEmpty;
    final canEdit = isSubEvent ? _canUpdateSubEvent : _canUpdateMainEvent; // RBAC: UPDATE berbeda antara main/sub.
    final canScan = canEdit && (isSubEvent || !hasSubEvents);
    final canDelete = isSubEvent ? _canDeleteSubEvent : _canDeleteMainEvent; // RBAC: DELETE berbeda antara main/sub.
    final canAddSubEvent = !isSubEvent && _canCreateSubEvent; // RBAC: CREATE sub-event boleh Executive/Manager pada parent main event.

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canScan)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ScanScreen(eventId: event.eventId),
                ),
              );
            },
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan'),
          ),
        if (canEdit)
          OutlinedButton.icon(
            onPressed: () => _addOrEditEvent(existing: event),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        if (canDelete)
          OutlinedButton.icon(
            onPressed: () => _deleteEvent(event),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        if (canAddSubEvent)
          OutlinedButton.icon(
            onPressed: () => _addOrEditEvent(forcedParentId: event.eventId),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Tambah Sub-Event'),
          ),
      ],
    );
  }

  Widget _buildEventCard(EventModel event) {
    final subEvents = _controller.getSubEvents(event.eventId);
    final isExpanded = _expandedState[event.eventId] ?? false;
    final attendance = _attendanceForEvent(event.eventId);
    final presentCount = attendance.where((r) => r.status.toLowerCase().contains('hadir')).length;
    final targetCount = _targetCount(event, presentCount);
    final attendancePercent = targetCount == 0 ? 0.0 : (presentCount / targetCount).clamp(0.0, 1.0);
    final attendanceText = '$presentCount/$targetCount hadir';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailView(event: event)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.nama,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: const Icon(Icons.schedule_outlined, size: 20, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_formatDate(event.tanggalMulai)} • ${event.jamMulai != null ? '${event.jamMulai!.hour.toString().padLeft(2, '0')}:${event.jamMulai!.minute.toString().padLeft(2, '0')} WIB' : 'WIB'}',
                                style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _eventLocation(event),
                                style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              child: const Icon(Icons.groups_outlined, size: 20, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              attendanceText,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _eventStatusBgColor(event),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: _eventStatusColor(event)),
                      const SizedBox(width: 6),
                      Text(
                        _eventStatusLabel(event),
                        style: TextStyle(
                          color: _eventStatusColor(event),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text(
                  'Kehadiran',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: attendancePercent,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        attendancePercent >= 0.9
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(attendancePercent * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            if (_hasAnyCrudAccess || subEvents.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (subEvents.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _expandedState[event.eventId] = !isExpanded;
                        });
                      },
                      icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                      label: Text(isExpanded ? 'Tutup Sub-Event' : 'Lihat Sub-Event'),
                    ),
                  const Spacer(),
                  if (_canUpdateMainEvent || _canDeleteMainEvent || _canCreateSubEvent)
                    _buildActionButtons(event),
                ],
              ),
            ],
            if (subEvents.isNotEmpty && isExpanded) ...[
              const SizedBox(height: 12),
              ...subEvents.map((sub) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.nama,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text('${sub.jenis} • ${_formatDate(sub.tanggalMulai)}'),
                      const SizedBox(height: 8),
                      _buildActionButtons(sub, forcedParentId: event.eventId),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _hasAnyCrudAccess ? 'Event (Partial CRUD)' : 'Event (Read-Only)'; // RBAC: Manager punya CRUD hanya untuk sub-event.

    return Scaffold(
      appBar: GradientHeader(
        title: title,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _controller.loadEvents(force: true),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          if (_canCreateMainEvent)
            IconButton(
              tooltip: 'Tambah Event',
              onPressed: () => _addOrEditEvent(),
              icon: const Icon(Icons.add, color: Colors.white),
            ),
        ],
      ),
      floatingActionButton: _canCreateMainEvent
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditEvent(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Event'),
            )
          : null,
      body: ValueListenableBuilder<List<EventModel>>(
        valueListenable: _controller.events,
        builder: (context, events, child) {
          final roots = _controller.getRootEvents();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Cari event...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(
                      _controller.selectedJenisFilter.value ?? 'Semua Jenis',
                    ),
                    selected: _controller.selectedJenisFilter.value != null,
                    onSelected: (_) => _showJenisFilter(),
                  ),
                  FilterChip(
                    label: const Text('Range Tanggal'),
                    selected: _controller.selectedDateRangeFilter.value != null,
                    onSelected: (_) => _showDateRangeFilter(),
                  ),
                  if (_controller.hasActiveFilters)
                    ActionChip(
                      label: const Text('Reset'),
                      onPressed: () {
                        _searchController.clear();
                        _controller.clearAllFilters();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (roots.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada event yang tersedia.'),
                  ),
                )
              else
                ...roots.map(_buildEventCard),
            ],
          );
        },
      ),
    );
  }
}

class _EventFormData {
  const _EventFormData({
    required this.name,
    required this.date,
    required this.jenis,
    this.parentEventId,
    this.lokasi,
    this.deskripsi,
    this.targetPeserta = const <String>[],
  });

  final String name;
  final DateTime date;
  final String jenis;
  final String? parentEventId;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;
}
