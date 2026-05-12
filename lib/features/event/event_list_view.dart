// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/sectioned_list_body.dart';
import '../../widgets/white_status_header.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/empty_state_widget.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart';
import 'event_detail_view.dart';
import 'event_form_view.dart';
import 'event_permission.dart';
import 'widgets/event_card.dart';
import 'widgets/event_filter_chips.dart';
import 'widgets/event_search_bar.dart';
import 'widgets/event_list_card.dart';
import 'widgets/event_list_utilities.dart';

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
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  void _updateExpandedState(String eventId, bool expanded) {
    setState(() {
      _expandedState[eventId] = expanded;
    });
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
    return EventListUtilities.formatDate(date);
  }

  String _formatDateTime(DateTime date) {
    return EventListUtilities.formatDateTime(date);
  }

  Color _getJenisColor(String jenis) {
    return EventListUtilities.getJenisColor(jenis);
  }

  Widget _buildEventListBuilder(
    BuildContext context,
    List<EventModel> rootEvents,
  ) {
    if (rootEvents.isEmpty) {
      return ListView(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.loadEvents(force: true, cloudSync: true),
      child: ListView.builder(
        itemCount: rootEvents.length,
        itemBuilder: (_, index) {
          final event = rootEvents[index];
          final subEvents =
              _controller.getSubEvents(event.eventId);

          return EventListCard(
            event: event,
            subEvents: subEvents,
            onAddSubEvent: () => _addSubEvent(event),
            onEditEvent: () => _editEvent(event),
            onDeleteEvent: () => _deleteEvent(event),
            onScanEvent: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ScanScreen(eventId: event.eventId),
                ),
              );
            },
            onEditSubEvent: _editEvent,
            onDeleteSubEvent: _deleteEvent,
            onScanSubEvent: (subEvent) {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ScanScreen(eventId: subEvent.eventId),
                ),
              );
            },
            getJenisColor: EventListUtilities.getJenisColor,
            formatDate: EventListUtilities.formatDate,
            formatDateTime: EventListUtilities.formatDateTime,
            canCreateSubEvent: _canCreateSubEvent,
            canUpdateMainEvent: _canUpdateMainEvent,
            canDeleteMainEvent: _canDeleteMainEvent,
            canUpdateSubEvent: _canUpdateSubEvent,
            canDeleteSubEvent: _canDeleteSubEvent,
            expandedState: _expandedState,
            onExpandedChanged: (expanded) =>
                _updateExpandedState(event.eventId, expanded),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhiteStatusHeader(
        title: 'Daftar Event',
        subtitle: 'Kelola main event dan sub-event',
        statusBadge: ValueListenableBuilder<bool>(
          valueListenable: NetworkStatusController.instance.isOnline,
          builder: (context, isOnline, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnline
                    ? const Color(0xFFE8F7EF)
                    : const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 10,
                    color: isOnline
                        ? const Color(0xFF15803D)
                        : const Color(0xFFF97316),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isOnline
                        ? 'TERSINKRONISASI'
                        : 'OFFLINE (SIMPAN LOKAL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isOnline
                          ? const Color(0xFF15803D)
                          : const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          if (_canCreateMainEvent)
            IconButton(
              tooltip: 'Tambah Event',
              onPressed: _addEvent,
              icon: const Icon(Icons.add, color: Color(0xFF111827)),
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

                return SectionedListBody(
                  header: const SizedBox.shrink(),
                  searchBar: EventSearchBar(
                    controller: _searchController,
                  ),
                  filterArea: EventFilterChips(
                    controller: _controller,
                    onJenisFilterTap: _showJenisFilter,
                    onDateFilterTap: _showDateRangeFilter,
                    onClearFilters: _clearAllFilters,
                  ),
                  listBuilder: (context) =>
                      _buildEventListBuilder(context, rootEvents),
                  emptyState: const SizedBox.shrink(),
                  onRefresh: () =>
                      _controller.loadEvents(force: true, cloudSync: true),
                );
              },
            ),
          );
        },
      ),
    );
  }
}