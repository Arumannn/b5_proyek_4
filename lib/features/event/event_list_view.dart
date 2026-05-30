import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_model.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/white_status_header.dart';
import '../auth/auth_controller.dart';
import 'event_controller.dart';
import 'event_detail_view.dart';
import 'event_form_view.dart';
import 'event_permission.dart';
import 'widgets/event_list_utilities.dart';

class EventListView extends StatefulWidget {
  final bool showBottomNav;

  const EventListView({super.key, this.showBottomNav = true});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final EventController _controller = EventController.instance;
  final TextEditingController _searchController = TextEditingController();
  String _activeTab = 'berlangsung'; // 'berlangsung', 'mendatang', 'selesai'
  String _searchQuery = '';

  String get _role =>
      (AuthController.instance.currentUser.value?.role ??
              AppConstants.roleMember)
          .trim()
          .toLowerCase();

  bool get _canCreateMainEvent => EventPermission.canCreateMainEvent(_role);

  @override
  void initState() {
    super.initState();
    _controller.loadEvents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
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

  Future<void> _addEvent() async {
    if (!_canCreateMainEvent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda tidak memiliki izin membuat event.'),
        ),
      );
      return;
    }

    final result = await Navigator.push<EventFormValue>(
      context,
      MaterialPageRoute<EventFormValue>(
        builder: (_) => EventFormView(
          title: 'Buat Event Baru',
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
      requiresInvitation: result.requiresInvitation,
      penyelenggara: result.penyelenggara,
      penanggungJawab: result.penanggungJawab,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event berhasil ditambahkan.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage.value ?? 'Gagal menambah event.',
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return EventListUtilities.formatDate(date);
  }

  String _formatTime(DateTime date) {
    // Basic time formatting HH:MM
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhiteStatusHeader(
        title: 'Daftar Event',
        subtitle: 'Daftar semua event',
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
                    isOnline ? 'TERSINKRONISASI' : 'OFFLINE (SIMPAN LOKAL)',
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
      backgroundColor: const Color(0xFFF9FAFB), // bg-gray-50
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Tabs Area
            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ), // px-4 pt-4 pb-2
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                  ), // border-b border-gray-200
                ),
              ),
              child: Column(
                children: [
                  // Search Input
                  Container(
                    margin: const EdgeInsets.only(bottom: 12), // mb-3
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6), // bg-gray-100
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Color(0xFF1F2937), // text-gray-800
                        fontSize: 14, // text-sm
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Cari nama event...',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ), // text-gray-400
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ), // py-2.5
                      ),
                    ),
                  ),

                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['berlangsung', 'mendatang', 'selesai'].map((
                        tab,
                      ) {
                        final isActive = _activeTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                          ), // space-x-2 equivalent
                          child: InkWell(
                            onTap: () => setState(() => _activeTab = tab),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ), // px-4 py-2
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF2563EB)
                                    : const Color(
                                        0xFFF3F4F6,
                                      ), // bg-blue-600 : bg-gray-100
                                borderRadius: BorderRadius.circular(
                                  999,
                                ), // rounded-full
                              ),
                              child: Text(
                                tab[0].toUpperCase() +
                                    tab.substring(1), // capitalize
                                style: TextStyle(
                                  fontSize: 14, // text-sm
                                  fontWeight: FontWeight.w500, // font-medium
                                  color: isActive
                                      ? Colors.white
                                      : const Color(
                                          0xFF4B5563,
                                        ), // text-white : text-gray-600
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // List Area
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isLoading,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ValueListenableBuilder<List<EventModel>>(
                    valueListenable: _controller.events,
                    builder: (context, allEvents, _) {
                      final rootEvents = allEvents.where((e) => e.parentEventId == null).toList(growable: false);
                      final filteredEvents = rootEvents.where((mainEvent) {
                        final statusMatches = mainEvent.statusEvent.toLowerCase() == _activeTab;
                        final searchMatches = mainEvent.nama.toLowerCase().contains(_searchQuery);
                        final relatedSubEvents = allEvents.where((event) => event.parentEventId == mainEvent.eventId).toList(growable: false);
                        final relatedSearchMatches = relatedSubEvents.any((sub) => sub.nama.toLowerCase().contains(_searchQuery));
                        return statusMatches && (searchMatches || relatedSearchMatches);
                      }).toList(growable: false);

                      return RefreshIndicator(
                        edgeOffset: 24,
                        displacement: 56,
                        strokeWidth: 3,
                        onRefresh: () => _controller.refreshEvents(cloudSync: true),
                        child: filteredEvents.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                children: [
                                  const SizedBox(height: 80),
                                  _buildEmptyState(),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16), // p-4
                                itemCount: filteredEvents.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 16), // space-y-4
                                itemBuilder: (context, index) {
                                  final mainEvent = filteredEvents[index];
                                  final relatedSubEvents = allEvents.where((event) {
                                    final isChild = event.parentEventId == mainEvent.eventId;
                                    final statusMatches = event.statusEvent.toLowerCase() == _activeTab;
                                    final searchMatches = event.nama.toLowerCase().contains(_searchQuery);
                                    return isChild && statusMatches && (searchMatches || _searchQuery.isEmpty);
                                  }).toList(growable: false);

                                  return _buildEventHierarchyCard(
                                    mainEvent,
                                    relatedSubEvents,
                                  );
                                },
                              ),
                      );
                    },
                  );
                },
              ),
            ),
            if (widget.showBottomNav)
              const SizedBox(height: 80), // pb-20 equivalent
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.event_busy_outlined, size: 36, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak ada event yang sesuai dengan pencarian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarik ke bawah untuk memuat ulang.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHierarchyCard(EventModel mainEvent, List<EventModel> relatedSubEvents) {
    final dateStr = _formatDate(mainEvent.tanggalMulai);
    final timeStart = _formatTime(mainEvent.jamMulai ?? mainEvent.tanggalMulai);
    final timeEnd = _formatTime(
      mainEvent.jamSelesai ??
          (mainEvent.tanggalSelesai ?? mainEvent.tanggalMulai.add(const Duration(hours: 1))),
    );
    final timeStr = '$timeStart - $timeEnd';
    final locationStr =
        (mainEvent.lokasi != null && mainEvent.lokasi!.trim().isNotEmpty)
            ? mainEvent.lokasi!
            : 'Lokasi belum ditentukan';
    final penanggungJawabStr =
        (mainEvent.penanggungJawab != null && mainEvent.penanggungJawab!.trim().isNotEmpty)
            ? mainEvent.penanggungJawab!
            : 'Belum diatur';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EventDetailView(
                  event: mainEvent,
                  userRole: _role,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
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
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'EVENT UTAMA',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mainEvent.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildEventLine(Icons.schedule_outlined, timeStr),
                      const SizedBox(height: 4),
                      _buildEventLine(Icons.location_on_outlined, locationStr),
                      const SizedBox(height: 4),
                      _buildEventLine(Icons.badge_outlined, penanggungJawabStr),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (relatedSubEvents.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 24),
            padding: const EdgeInsets.only(left: 16),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: relatedSubEvents.map((subEvent) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EventDetailView(
                            event: subEvent,
                            userRole: _role,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: -18,
                            top: 10,
                            child: Icon(
                              Icons.subdirectory_arrow_right_outlined,
                              size: 14,
                              color: Colors.grey.shade300,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FFFB),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'SUB-EVENT',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F766E),
                                          letterSpacing: 0.7,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(subEvent.jamMulai ?? subEvent.tanggalMulai),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subEvent.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_formatDate(subEvent.tanggalMulai)} • ${subEvent.lokasi ?? 'Lokasi belum ditentukan'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEventLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}
