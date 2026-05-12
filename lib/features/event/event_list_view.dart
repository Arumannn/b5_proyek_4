// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/empty_state_widget.dart';
import 'event_controller.dart';
import 'event_detail_view.dart';
import 'event_form_view.dart';
import 'event_permission.dart';
import 'widgets/event_card.dart';
import 'widgets/event_filter_chips.dart';
import 'widgets/event_search_bar.dart';

/// Layar daftar event (Executive) — Enhanced Week 9 Sub-Tahap B
///
/// FITUR BARU:
/// - Expandable Main Event dengan Sub-Event
/// - Filter berdasarkan jenis dan range tanggal
/// - Search bar untuk cari event
/// - Empty state yang informatif
/// - Chip untuk menampilkan filter aktif
/// - Better UX dengan animasi smooth
class EventListView extends StatefulWidget {
  final bool showBottomNav;

  const EventListView({super.key, this.showBottomNav = true});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final EventController _controller = EventController.instance;
  final Map<String, bool> _expandedState = {}; // Track expanded/collapsed state
  final TextEditingController _searchController = TextEditingController();

  String get _role =>
      (AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember)
          .trim()
          .toLowerCase(); // RBAC: gunakan role user login aktif untuk kontrol UI aksi.

  bool get _canCreateMainEvent => EventPermission.canCreateMainEvent(_role); // RBAC: Main event CREATE hanya Executive.
  bool get _canUpdateMainEvent => EventPermission.canUpdateMainEvent(_role); // RBAC: Main event UPDATE hanya Executive.
  bool get _canDeleteMainEvent => EventPermission.canDeleteMainEvent(_role); // RBAC: Main event DELETE hanya Executive.
  bool get _canCreateSubEvent => EventPermission.canCreateSubEvent(_role); // RBAC: Sub-event CREATE untuk Executive/Manager.
  bool get _canUpdateSubEvent => EventPermission.canUpdateSubEvent(_role); // RBAC: Sub-event UPDATE untuk Executive/Manager.
  bool get _canDeleteSubEvent => EventPermission.canDeleteSubEvent(_role); // RBAC: Sub-event DELETE untuk Executive/Manager.

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

  List<EventParentOption> get _parentOptions {
    return _controller
        .getRootEvents()
        .map((event) => EventParentOption(id: event.eventId, name: event.nama))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _showJenisFilter() async {
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
            ..._controller.events.value
                .map((e) => e.jenis)
                .toSet()
                .map((jenis) {
              return SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, jenis),
                child: Text(jenis),
              );
            }),
          ],
        );
      },
    );

    if (selected != null || selected == null) {
      _controller.setJenisFilter(selected);
    }
  }

  Future<void> _showDateRangeFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
      saveText: 'Terapkan',
      helpText: 'Pilih Range Tanggal',
      cancelText: 'Batal',
      fieldStartLabelText: 'Dari',
      fieldEndLabelText: 'Sampai',
    );

    if (picked != null) {
      _controller.setDateRangeFilter(picked);
    }
  }

  void _clearAllFilters() {
    _searchController.clear();
    _controller.clearAllFilters();
    CustomSnackbar.showInfo(context, 'Filter dibersihkan');
  }

  // ═══════════════════════════════════════════════════════════════
  // EVENT CRUD ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _addEvent() async {
    if (!_canCreateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat main event.'); // RBAC: cegah CREATE main event tanpa izin.
      return;
    }

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
      tanggalMulai: result.date,
      tanggalSelesai: result.endDate,
      jamSelesai: result.jamSelesai,
      parentEventId: result.isSubEvent ? result.parentId : null,
      jenis: result.jenis,
      lokasi: result.lokasi,
      deskripsi: result.deskripsi,
      targetPeserta: result.targetPeserta,
      penyelenggara: result.penyelenggara,
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
    final isSubEvent = target.parentEventId != null; // RBAC: UPDATE permission ditentukan dari scope event.
    if (!isSubEvent && !_canUpdateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah main event.'); // RBAC: cegah UPDATE main event tanpa izin.
      return;
    }
    if (isSubEvent && !_canUpdateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah sub-event.'); // RBAC: cegah UPDATE sub-event tanpa izin.
      return;
    }

    final result = await Navigator.push<EventFormValue>(
      context,
      MaterialPageRoute<EventFormValue>(
        builder: (_) => EventFormView(
          title: 'Edit Event',
          canChangeHierarchy: false,
          parentOptions: _parentOptions,
          initialValue: EventFormValue(
            name: target.nama,
            date: target.tanggalMulai,
            endDate: target.tanggalSelesai,
            jamSelesai: target.jamSelesai,
            isSubEvent: isSubEvent,
            parentId: target.parentEventId,
            jenis: target.jenis,
            lokasi: target.lokasi,
            targetPeserta: target.targetPeserta,
          ),
        ),
      ),
    );

    if (result == null) return;

    final success = await _controller.updateEvent(
      target.copyWith(
        nama: result.name,
        tanggalMulai: result.date,
        tanggalSelesai: result.endDate,
        jamSelesai: result.jamSelesai,
        jenis: result.jenis,
        lokasi: result.lokasi,
        targetPeserta: result.targetPeserta,
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
    final isSubEvent = target.parentEventId != null; // RBAC: DELETE permission ditentukan dari scope event.
    if (!isSubEvent && !_canDeleteMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus main event.'); // RBAC: cegah DELETE main event tanpa izin.
      return;
    }
    if (isSubEvent && !_canDeleteSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus sub-event.'); // RBAC: cegah DELETE sub-event tanpa izin.
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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

  // ═══════════════════════════════════════════════════════════════
  // UI BUILDERS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari event, jenis, atau lokasi...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return ValueListenableBuilder<String?>(
      valueListenable: _controller.selectedJenisFilter,
      builder: (_, jenisFilter, _) {
        return ValueListenableBuilder<DateTimeRange?>(
          valueListenable: _controller.selectedDateRangeFilter,
          builder: (_, dateRange, _) {
            final hasFilters = _controller.hasActiveFilters;
            final chipShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Filter Jenis Button
                  FilterChip(
                    label: Text(jenisFilter ?? 'Semua Jenis'),
                    selected: jenisFilter != null,
                    onSelected: (_) => _showJenisFilter(),
                    avatar: const Icon(Icons.category_outlined, size: 18),
                    shape: chipShape,
                    showCheckmark: false,
                    selectedColor: const Color(0xFFDBEAFE),
                    labelStyle: TextStyle(
                      fontWeight: jenisFilter != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: jenisFilter != null
                          ? const Color(0xFF1D4ED8)
                          : Colors.black87,
                    ),
                  ),
                  
                  // Filter Tanggal Button
                  FilterChip(
                    label: Text(
                      dateRange != null
                          ? '${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}'
                          : 'Semua Tanggal',
                    ),
                    selected: dateRange != null,
                    onSelected: (_) => _showDateRangeFilter(),
                    avatar: const Icon(Icons.date_range, size: 18),
                    shape: chipShape,
                    showCheckmark: false,
                    selectedColor: const Color(0xFFDCFCE7),
                    labelStyle: TextStyle(
                      fontWeight: dateRange != null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: dateRange != null
                          ? const Color(0xFF166534)
                          : Colors.black87,
                    ),
                  ),

                  // Clear All Filters
                  if (hasFilters)
                    ActionChip(
                      label: const Text('Reset Filter'),
                      onPressed: _clearAllFilters,
                      avatar: const Icon(Icons.clear_all, size: 18),
                      shape: chipShape,
                      backgroundColor: const Color(0xFFF3F4F6),
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubEventItem(EventModel subEvent) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subEvent.nama,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aksi',
                onSelected: (value) {
                  if (value == 'edit') {
                    _editEvent(subEvent);
                  } else if (value == 'delete') {
                    _deleteEvent(subEvent);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    if (_canUpdateSubEvent)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (_canDeleteSubEvent)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ];
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getJenisColor(subEvent.jenis).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  subEvent.jenis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getJenisColor(subEvent.jenis),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(subEvent.tanggalMulai),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_canUpdateSubEvent)
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ScanScreen(eventId: subEvent.eventId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Scan'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    foregroundColor: const Color(0xFF1D4ED8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, {List<EventModel> subEvents = const []}) {
    final eventId = event.eventId;
    final isExpanded = _expandedState[eventId] ?? false;
    final hasSubEvents = subEvents.isNotEmpty;
    final hasLocation = (event.lokasi ?? '').trim().isNotEmpty;
    final dateLabel = _formatDateTime(event.jamMulai ?? event.tanggalMulai);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: hasSubEvents
            ? () {
                setState(() {
                  _expandedState[eventId] = !isExpanded;
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getJenisColor(event.jenis).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  event.jenis.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: _getJenisColor(event.jenis),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // ── Header Row ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.nama,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (hasLocation) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.lokasi!.trim(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Expand/Collapse Icon
                  if (hasSubEvents)
                    Icon(
                      isExpanded 
                          ? Icons.expand_less 
                          : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  else if (_canCreateSubEvent)
                    IconButton(
                      tooltip: 'Tambah Sub Event',
                      onPressed: () => _addSubEvent(event),
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  PopupMenuButton<String>(
                    tooltip: 'Aksi',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editEvent(event);
                      } else if (value == 'delete') {
                        _deleteEvent(event);
                      }
                    },
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        if (_canUpdateMainEvent)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (_canDeleteMainEvent)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus'),
                          ),
                      ];
                    },
                  ),
                ],
              ),

              if (hasSubEvents) ...[
                const SizedBox(height: 8),
                Text(
                  '${subEvents.length} sub event',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],

              const SizedBox(height: 12),

              // ── Action Buttons ────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!hasSubEvents)
                    if (_canUpdateMainEvent)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ScanScreen(eventId: event.eventId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                ],
              ),

              // ── Sub Events (Expandable) ───────────────
              if (hasSubEvents && isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Text(
                  'Sub Event',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ...subEvents.map(_buildSubEventItem),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSubEvent(EventModel parentEvent) async {
    if (!_canCreateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat sub-event.'); // RBAC: cegah CREATE sub-event tanpa izin.
      return;
    }

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
            endDate: DateTime.now().add(const Duration(hours: 1)),
            isSubEvent: true,
            parentId: parentEvent.eventId,
          ),
        ),
      ),
    );

    if (result == null) return;

    final success = await _controller.createEvent(
      nama: result.name,
      tanggalMulai: result.date,
      tanggalSelesai: result.endDate,
      parentEventId: parentEvent.eventId,
      jenis: result.jenis,
      lokasi: result.lokasi,
      deskripsi: result.deskripsi,
      targetPeserta: result.targetPeserta,
      penyelenggara: result.penyelenggara,
    );

    if (!mounted) return;
    if (success) {
      setState(() {
        _expandedState[parentEvent.eventId] = true; // Auto-expand after add
      });
      CustomSnackbar.showSuccess(context, 'Sub event berhasil ditambahkan.');
    } else {
      CustomSnackbar.showError(
        context,
        _controller.errorMessage.value ?? 'Gagal menambah sub event.',
      );
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatDateTime(DateTime date) {
    final datePart = _formatDate(date);
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$datePart $hh:$mm';
  }

  Color _getJenisColor(String jenis) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientHeader(
        title: 'Daftar Event',
        subtitle: 'Kelola main event dan sub-event',
        actions: [
          if (_canCreateMainEvent)
            IconButton(
              tooltip: 'Tambah Event',
              onPressed: _addEvent,
              icon: const Icon(Icons.add, color: Colors.white),
            ),
        ],
      ),
      floatingActionButton: _canCreateMainEvent
          ? FloatingActionButton.extended(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Event'),
            )
          : null,
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, _) {
          return LoadingOverlay(
            isLoading: isLoading,
            message: 'Memuat event...',
            child: ValueListenableBuilder<List<EventModel>>(
              valueListenable: _controller.events,
              builder: (context, allEvents, _) {
                final rootEvents = _controller.getRootEvents();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Search Bar ──────────────────────
                      EventSearchBar(controller: _searchController),

                      // ── Filter Chips ────────────────────
                      EventFilterChips(
                        controller: _controller,
                        onJenisFilterTap: _showJenisFilter,
                        onDateFilterTap: _showDateRangeFilter,
                        onClearFilters: _clearAllFilters,
                      ),

                      // ── Event List ──────────────────────
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _controller.loadEvents(force: true, cloudSync: true),
                          child: rootEvents.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                    EmptyStateWidget(
                                      icon: _controller.hasActiveFilters
                                          ? Icons.filter_list_off
                                          : Icons.event_busy,
                                      title: _controller.hasActiveFilters
                                          ? 'Tidak ada event yang cocok'
                                          : 'Belum ada event',
                                      subtitle: _controller.hasActiveFilters
                                          ? 'Coba ubah filter atau reset untuk melihat semua event'
                                          : 'Tekan tombol + untuk menambah event pertama',
                                      action: _controller.hasActiveFilters
                                          ? FilledButton.icon(
                                              onPressed: _clearAllFilters,
                                              icon: const Icon(Icons.clear_all),
                                              label: const Text('Reset Filter'),
                                            )
                                          : null,
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: rootEvents.length,
                                  itemBuilder: (context, index) {
                                    final event = rootEvents[index];
                                    final subEvents = _controller.getSubEvents(event.eventId);

                                    return EventCard(
                                      event: event,
                                      subEvents: subEvents,
                                      isExpanded: _expandedState[event.eventId] ?? false,
                                      canUpdateMain: _canUpdateMainEvent,
                                      canDeleteMain: _canDeleteMainEvent,
                                      canCreateSub: _canCreateSubEvent,
                                      canUpdateSub: _canUpdateSubEvent,
                                      canDeleteSub: _canDeleteSubEvent,
                                      onExpandToggle: (expanded) {
                                        setState(() => _expandedState[event.eventId] = expanded);
                                      },
                                      onCardTap: () {
                                        final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
                                        );
                                      },
                                      onEdit: _editEvent,
                                      onDelete: _deleteEvent,
                                      onAddSubEvent: _addSubEvent,
                                      onScan: (eventId) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ScanScreen(eventId: eventId),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
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