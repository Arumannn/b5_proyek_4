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
      penyelenggara: result.penyelenggara,
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
        title: 'Katalog Event',
        subtitle: 'Daftar semua kegiatan HIMAKOM',
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
                      // Filter events
                      final filteredEvents = allEvents.where((e) {
                        final statusMatches =
                            (e.statusEvent.toLowerCase() == _activeTab);
                        final searchMatches = e.nama.toLowerCase().contains(
                          _searchQuery,
                        );
                        return statusMatches && searchMatches;
                      }).toList();

                      if (filteredEvents.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40), // mt-10
                            child: Text(
                              'Tidak ada event yang sesuai dengan pencarian Anda.',
                              style: TextStyle(
                                color: const Color(0xFF6B7280), // text-gray-500
                                fontSize: 14, // text-sm
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => _controller.loadEvents(
                          force: true,
                          cloudSync: true,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16), // p-4
                          itemCount: filteredEvents.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16), // space-y-4
                          itemBuilder: (context, index) {
                            final event = filteredEvents[index];
                            final isSubEvent = event.parentEventId != null;
                            final eventType = isSubEvent
                                ? 'Sub-Event'
                                : 'Event Utama';

                            final dateStr = _formatDate(event.tanggalMulai);
                            final timeStart = _formatTime(
                              event.jamMulai ?? event.tanggalMulai,
                            );
                            final timeEnd = _formatTime(
                              event.jamSelesai ??
                                  (event.tanggalSelesai ??
                                      event.tanggalMulai.add(
                                        const Duration(hours: 1),
                                      )),
                            );
                            final timeStr = '$timeStart - $timeEnd';
                            final locationStr =
                                (event.lokasi != null &&
                                    event.lokasi!.trim().isNotEmpty)
                                ? event.lokasi!
                                : 'Lokasi belum ditentukan';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => EventDetailView(
                                      event: event,
                                      userRole: _role,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16), // p-4
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // rounded-xl
                                  border: Border.all(
                                    color: Colors.grey.shade100,
                                  ), // border-gray-100
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1), // shadow-sm
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          eventType.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10, // text-[10px]
                                            fontWeight: FontWeight.bold,
                                            color: Color(
                                              0xFF6B7280,
                                            ), // text-gray-500
                                            letterSpacing:
                                                0.5, // uppercase tracking
                                          ),
                                        ),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 12, // text-xs
                                            fontWeight: FontWeight
                                                .w600, // font-semibold
                                            color: Color(
                                              0xFF1F2937,
                                            ), // text-gray-800
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8), // mb-2
                                    Text(
                                      event.nama,
                                      style: const TextStyle(
                                        fontSize: 16, // text-base
                                        fontWeight: FontWeight.bold,
                                        color: Color(
                                          0xFF1F2937,
                                        ), // text-gray-800
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ), // mb-4 mapped to 8 + spacing
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: Color(0xFF9CA3AF),
                                        ), // text-gray-400
                                        const SizedBox(width: 8), // mr-2
                                        Expanded(
                                          child: Text(
                                            timeStr,
                                            style: const TextStyle(
                                              fontSize: 12, // text-xs
                                              color: Color(
                                                0xFF4B5563,
                                              ), // text-gray-600
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ), // space-y-1 equivalent
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 12,
                                          color: Color(0xFF9CA3AF),
                                        ), // text-gray-400
                                        const SizedBox(width: 8), // mr-2
                                        Expanded(
                                          child: Text(
                                            locationStr,
                                            style: const TextStyle(
                                              fontSize: 12, // text-xs
                                              color: Color(
                                                0xFF4B5563,
                                              ), // text-gray-600
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
}
