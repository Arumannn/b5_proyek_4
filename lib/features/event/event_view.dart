// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/white_status_header.dart';
import '../../widgets/sectioned_list_body.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart'; 
import 'event_permission.dart';
import 'widgets/event_utilities.dart';
import 'widgets/event_view_card.dart';
import 'event_detail_view.dart';
import '../attendance/scan_screen.dart';

class EventView extends StatefulWidget {
  const EventView({super.key});

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView> {
  final EventController _controller = EventController.instance;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedState = <String, bool>{};
  String _selectedTab = 'mendatang';

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
  bool get _canDeleteSubEvent => EventPermission.canDeleteSubEvent(_role); // RBAC: Sub-event DELETE untuk Executive/Manager.
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

  String _normalizedStatus(String value) {
    return value.trim().toLowerCase();
  }

  bool _matchesSelectedTab(EventModel event) {
    final status = _normalizedStatus(event.statusEvent);

    switch (_selectedTab) {
      case 'berlangsung':
        return status.contains('berlangsung') || status.contains('berjalan');
      case 'selesai':
        return status.contains('selesai');
      default:
        return status.contains('mendatang') ||
            status.contains('upcoming') ||
            (!status.contains('berlangsung') && !status.contains('selesai'));
    }
  }

  List<EventModel> _visibleRootEvents() {
    return _controller.getRootEvents().where(_matchesSelectedTab).toList(growable: false);
  }

  Color _eventAccentColor(EventModel event) {
    final status = _normalizedStatus(event.statusEvent);
    if (status.contains('selesai')) return const Color(0xFF22C55E);
    if (status.contains('berlangsung') || status.contains('berjalan')) return const Color(0xFF2563EB);
    return const Color(0xFFF97316);
  }

  Color _eventTintColor(EventModel event) {
    final accent = _eventAccentColor(event);
    if (accent == const Color(0xFF2563EB)) return const Color(0xFFDBEAFE);
    if (accent == const Color(0xFF22C55E)) return const Color(0xFFDCFCE7);
    return const Color(0xFFFFF7ED);
  }

  String _eventStatusTitle(EventModel event) {
    final status = _normalizedStatus(event.statusEvent);
    if (status.contains('selesai')) return 'Selesai';
    if (status.contains('berlangsung') || status.contains('berjalan')) return 'Berlangsung';
    return 'Mendatang';
  }

  Widget _buildTabPill(String label) {
    final selected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceEventCard(EventModel event) {
    final accent = _eventAccentColor(event);
    final tint = _eventTintColor(event);
    final status = _eventStatusTitle(event);
    final dateText = _formatDate(event.tanggalMulai);
    final startTime = event.jamMulai ?? event.tanggalMulai;
    final timeText = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final location = _eventLocation(event);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
          );
        },
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: tint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                event.jenis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              event.nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildEventMetaRow(Icons.schedule_outlined, '$timeText WIB', const Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  _buildEventMetaRow(Icons.location_on_outlined, location, const Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  _buildEventMetaRow(Icons.groups_outlined, '${_targetCount(event, 0)} target peserta', const Color(0xFF6B7280)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMetaRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
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
            penyelenggara: form.penyelenggara,
            penanggungJawab: form.penanggungJawab,
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
              penyelenggara: form.penyelenggara,
              penanggungJawab: form.penanggungJawab,
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
    final penanggungJawabController = TextEditingController(
      text: initial?.penanggungJawab ?? '',
    );

    DateTime selectedDate = initial?.tanggalMulai ?? DateTime.now();
    String selectedJenis = initial?.jenis ?? ConfigController.instance.eventTypes.first;
    bool isSubEvent = forcedParentId != null || initial?.parentEventId != null;
    String? parentId = forcedParentId ?? initial?.parentEventId;
    Set<String> targetDivisi = Set<String>.from(
      initial?.targetPeserta ?? const [],
    );
    String? selectedPenyelenggara = initial?.penyelenggara;

    final allDbu = ConfigController.instance.allDbuOptions;

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
                          items: ConfigController.instance.eventTypes
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
                        DropdownButtonFormField<String>(
                          initialValue: selectedPenyelenggara,
                          decoration: const InputDecoration(
                            labelText: 'Penyelenggara',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                          isExpanded: true,
                          items: ConfigController.instance.penyelenggaraOptions
                              .map(
                                (p) => DropdownMenuItem<String>(
                                  value: p,
                                  child: Text(p),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedPenyelenggara = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: penanggungJawabController,
                          decoration: const InputDecoration(
                            labelText: 'Penanggung Jawab',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
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
                            labelText: 'Lokasi',
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
                            'Target Divisi *',
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
                        const SizedBox(height: 8),
                        if (targetDivisi.isEmpty)
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Wajib pilih minimal 1 target divisi.',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
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
                    if (targetDivisi.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Target divisi wajib dipilih (minimal 1).')),
                      );
                      return;
                    }
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
                        penyelenggara: selectedPenyelenggara,
                          penanggungJawab: penanggungJawabController.text.trim().isEmpty
                              ? null
                              : penanggungJawabController.text.trim(),
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
    penanggungJawabController.dispose();
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
                      final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
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
                                '${_formatDate(event.tanggalMulai)} • ${_formatTime(event.jamMulai ?? event.tanggalMulai)} WIB',
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
    return Scaffold(
      appBar: WhiteStatusHeader(
        title: 'Event',
        subtitle: _hasAnyCrudAccess
            ? 'Cari dan kelola event yang tersedia'
            : 'Cari dan buka detail event',
        actions: [
          IconButton(
            tooltip: 'Refresh',
              onPressed: () => _controller.refreshEvents(cloudSync: true),
            icon: const Icon(Icons.refresh, color: Color(0xFF111827)),
          ),
          if (_canCreateMainEvent)
            IconButton(
              tooltip: 'Tambah Event',
              onPressed: () => _addOrEditEvent(),
              icon: const Icon(Icons.add, color: Color(0xFF111827)),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F7FD),
      body: ValueListenableBuilder<List<EventModel>>(
        valueListenable: _controller.events,
        builder: (context, events, child) {
          final roots = _visibleRootEvents();

          return SafeArea(
            child: SectionedListBody(
              searchArea: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nama event...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTabPill('berlangsung'),
                      const SizedBox(width: 8),
                      _buildTabPill('mendatang'),
                      const SizedBox(width: 8),
                      _buildTabPill('selesai'),
                    ],
                  ),
                ],
              ),
              filterArea: _controller.hasActiveFilters
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: Text(_controller.selectedJenisFilter.value ?? 'Semua Jenis'),
                            onPressed: _showJenisFilter,
                          ),
                          ActionChip(
                            label: const Text('Range Tanggal'),
                            onPressed: _showDateRangeFilter,
                          ),
                          ActionChip(
                            label: const Text('Reset'),
                            onPressed: () {
                              _searchController.clear();
                              _controller.clearAllFilters();
                            },
                          ),
                        ],
                      ),
                    )
                  : null,
              content: RefreshIndicator(
                edgeOffset: 24,
                displacement: 56,
                strokeWidth: 3,
                onRefresh: () async => _controller.refreshEvents(cloudSync: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    if (roots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: const Text(
                          'Tidak ada event yang sesuai dengan pencarian Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      )
                    else
                      ...roots.map(
                        (event) => EventViewCard(
                          event: event,
                          controller: _controller,
                          expandedState: _expandedState,
                          canUpdateMainEvent: _canUpdateMainEvent,
                          canUpdateSubEvent: _canUpdateSubEvent,
                          canDeleteMainEvent: _canDeleteMainEvent,
                          canDeleteSubEvent: _canDeleteSubEvent,
                          canCreateSubEvent: _canCreateSubEvent,
                          hasAnyCrudAccess: _hasAnyCrudAccess,
                          onEdit: () => _addOrEditEvent(existing: event),
                          onDelete: () => _deleteEvent(event),
                          onAddSubEvent: () => _addOrEditEvent(forcedParentId: event.eventId),
                          onExpandedChanged: () => setState(() {}),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper methods delegating to EventUtilities
  String _formatDate(DateTime date) => EventUtilities.formatDate(date);

  String _formatTime(DateTime dateTime) =>
      '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  
  String _eventLocation(EventModel event) => EventUtilities.eventLocation(event);
  
  String _eventStatusLabel(EventModel event) => EventUtilities.eventStatusLabel(event);
  
  Color _eventStatusColor(EventModel event) => EventUtilities.eventStatusColor(event);
  
  Color _eventStatusBgColor(EventModel event) => EventUtilities.eventStatusBgColor(event);
  
  int _targetCount(EventModel event, int presentCount) => EventUtilities.targetCount(event, presentCount);
  
  List<AttendanceRecord> _attendanceForEvent(String eventId) => EventUtilities.attendanceForEvent(eventId);
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
    this.penyelenggara,
    this.penanggungJawab,
  });

  final String name;
  final DateTime date;
  final String jenis;
  final String? parentEventId;
  final String? lokasi;
  final String? deskripsi;
  final List<String> targetPeserta;
  final String? penyelenggara;
  final String? penanggungJawab;
}
