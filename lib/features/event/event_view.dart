import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/custom_confirm_dialog.dart';
import '../../widgets/white_status_header.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart'; 
import 'event_permission.dart';
import 'widgets/event_form_dialog.dart';
import 'widgets/event_view_card.dart';
import 'widgets/reference_event_card.dart';
import 'widgets/event_tab_pill.dart';
import 'widgets/event_utilities.dart';

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

  bool get _canCreateMainEvent => EventPermission.canCreateMainEvent(_role); 
  bool get _canUpdateMainEvent => EventPermission.canUpdateMainEvent(_role); 
  bool get _canDeleteMainEvent => EventPermission.canDeleteMainEvent(_role); 
  bool get _canCreateSubEvent => EventPermission.canCreateSubEvent(_role); 
  bool get _canUpdateSubEvent => EventPermission.canUpdateSubEvent(_role); 
  bool get _canDeleteSubEvent => EventPermission.canDeleteSubEvent(_role); 
  bool get _hasAnyCrudAccess => _canCreateMainEvent || _canCreateSubEvent; 

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

  bool _matchesSelectedTab(EventModel event) {
    final status = EventUtilities.normalizedStatus(event.statusEvent);

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

  Future<void> _addOrEditEvent({
    EventModel? existing,
    String? forcedParentId,
  }) async {
    final isCreate = existing == null; 
    final isSubEvent = 
        forcedParentId != null || (existing?.parentEventId != null);

    if (isCreate && !isSubEvent && !_canCreateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat main event.');
      return;
    }
    if (isCreate && isSubEvent && !_canCreateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin membuat sub-event.'); 
      return;
    }
    if (!isCreate && !isSubEvent && !_canUpdateMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah main event.'); 
      return;
    }
    if (!isCreate && isSubEvent && !_canUpdateSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin mengubah sub-event.'); 
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
            requiresInvitation: form.requiresInvitation,
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
              requiresInvitation: form.requiresInvitation,
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
    final isSubEvent = target.parentEventId != null; 
    if (!isSubEvent && !_canDeleteMainEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus main event.'); 
      return;
    }
    if (isSubEvent && !_canDeleteSubEvent) {
      CustomSnackbar.showError(context, 'Anda tidak memiliki izin menghapus sub-event.'); 
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return CustomConfirmDialog(
          title: 'Hapus Event',
          content: 'Yakin ingin menghapus "${target.nama}"?',
          confirmText: 'Hapus',
          isDestructive: true,
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

  Future<EventFormData?> _showEventFormDialog({
    required String title,
    EventModel? initial,
    String? forcedParentId,
  }) async {
    return await showDialog<EventFormData>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return EventFormDialog(
          title: title,
          initial: initial,
          forcedParentId: forcedParentId,
          parentOptions: _parentOptions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhiteStatusHeader(
        title: 'Event',
        subtitle: _hasAnyCrudAccess
            ? 'Cari dan kelola event yang tersedia'
            : 'Jelajahi berbagai event dan kegiatan',
      ),
      floatingActionButton: _canCreateMainEvent
          ? FloatingActionButton(
              onPressed: () => _addOrEditEvent(),
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<List<EventModel>>(
            valueListenable: _controller.events,
            builder: (context, events, child) {
              if (events.isEmpty && !_controller.hasActiveFilters) {
                return RefreshIndicator(
                  onRefresh: () => _controller.refreshEvents(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Text(
                          'Belum ada event tersedia.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final visibleEvents = _controller.hasActiveFilters || _searchController.text.isNotEmpty
                  ? events
                  : _visibleRootEvents();

              return RefreshIndicator(
                onRefresh: () => _controller.refreshEvents(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Cari event berdasarkan nama...',
                                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Color(0xFF9CA3AF)),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ActionChip(
                                    label: Text(
                                      _controller.selectedJenisFilter.value ?? 'Semua Jenis',
                                      style: TextStyle(
                                        color: _controller.selectedJenisFilter.value != null
                                            ? Colors.white
                                            : const Color(0xFF4B5563),
                                      ),
                                    ),
                                    backgroundColor: _controller.selectedJenisFilter.value != null
                                        ? const Color(0xFF2563EB)
                                        : Colors.white,
                                    onPressed: _showJenisFilter,
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                    label: Text(
                                      _controller.selectedDateRangeFilter.value != null
                                          ? 'Tanggal Terpilih'
                                          : 'Semua Tanggal',
                                      style: TextStyle(
                                        color: _controller.selectedDateRangeFilter.value != null
                                            ? Colors.white
                                            : const Color(0xFF4B5563),
                                      ),
                                    ),
                                    backgroundColor: _controller.selectedDateRangeFilter.value != null
                                        ? const Color(0xFF2563EB)
                                        : Colors.white,
                                    onPressed: _showDateRangeFilter,
                                  ),
                                  if (_controller.hasActiveFilters) ...[
                                    const SizedBox(width: 8),
                                    ActionChip(
                                      label: const Text('Reset', style: TextStyle(color: Colors.red)),
                                      backgroundColor: Colors.red.shade50,
                                      onPressed: () {
                                        _searchController.clear();
                                        _controller.clearAllFilters();
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_controller.hasActiveFilters && _searchController.text.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                EventTabPill(
                                  label: 'Mendatang',
                                  isSelected: _selectedTab == 'mendatang',
                                  onTap: () => setState(() => _selectedTab = 'mendatang'),
                                ),
                                EventTabPill(
                                  label: 'Berlangsung',
                                  isSelected: _selectedTab == 'berlangsung',
                                  onTap: () => setState(() => _selectedTab = 'berlangsung'),
                                ),
                                EventTabPill(
                                  label: 'Selesai',
                                  isSelected: _selectedTab == 'selesai',
                                  onTap: () => setState(() => _selectedTab = 'selesai'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final event = visibleEvents[index];
                            if (_searchController.text.isNotEmpty || _controller.hasActiveFilters) {
                              return ReferenceEventCard(event: event);
                            }
                            return EventViewCard(
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
                            );
                          },
                          childCount: visibleEvents.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
