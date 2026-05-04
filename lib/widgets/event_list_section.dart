import 'package:flutter/material.dart';
import '../features/event/event_controller.dart';
import '../features/event/event_detail_view.dart';
import '../models/event_model.dart';

class EventListSection extends StatefulWidget {
  const EventListSection({Key? key}) : super(key: key);

  @override
  State<EventListSection> createState() => _EventListSectionState();
}

class _EventListSectionState extends State<EventListSection> {
  // 0 = Kegiatan Terakhir, 1 = Mendatang
  // Sesuai gambar, kita jadikan 'Mendatang' (1) sebagai default yang aktif
  int _activeTabIndex = 1; 
  final EventController _eventController = EventController.instance;

  final List<Color> _headerColors = const [
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
    Color(0xFFF97316),
    Color(0xFF22C55E),
  ];

  @override
  void initState() {
    super.initState();
    _eventController.loadEvents();
  }

  // Helper untuk membuat tombol tab (Kegiatan Terakhir / Mendatang)
  Widget _buildTabButton(String title, int index) {
    bool isActive = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isActive ? Colors.blueAccent : Colors.grey[300]!,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[700],
              fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat Kartu Event yang warna-warni
  Widget _buildEventCard({
    required Color headerColor,
    required String title,
    required String date,
    required String time,
    required String location,
    required String participants,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- BAGIAN ATAS (Berwarna) ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: headerColor,
              // Melengkungkan sudut atas saja
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(date, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('•', style: TextStyle(color: Colors.white)),
                    ),
                    const Icon(Icons.access_time, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          
          // --- BAGIAN BAWAH (Putih) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Colors.grey[500], size: 18),
                    const SizedBox(width: 12),
                    Text(location, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey[500], size: 18),
                    const SizedBox(width: 12),
                    Text(participants, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                // Tombol Lihat Detail & Daftar
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Lihat Detail & Daftar',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month';
  }

  String _formatTime(DateTime date) {
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- TAB BUTTONS ---
        Row(
          children: [
            _buildTabButton('Kegiatan Terakhir', 0),
            const SizedBox(width: 12),
            _buildTabButton('Mendatang', 1),
          ],
        ),
        const SizedBox(height: 20),

        // --- DAFTAR EVENT BERDASARKAN TAB ---
        ValueListenableBuilder<List<EventModel>>(
          valueListenable: _eventController.events,
          builder: (context, events, _) {
            final now = DateTime.now();
            final rootEvents = events
                .where((e) => e.parentEventId == null)
                .toList(growable: false);

            final filtered = rootEvents.where((event) {
              final isPast = event.tanggal.isBefore(now);
              return _activeTabIndex == 0 ? isPast : !isPast;
            }).toList(growable: false);

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    _activeTabIndex == 0
                        ? 'Belum ada kegiatan terakhir.'
                        : 'Belum ada kegiatan mendatang.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              );
            }

            return Column(
              children: List.generate(filtered.length, (index) {
                final event = filtered[index];
                final headerColor = _headerColors[
                    index % _headerColors.length];
                final timeBase = event.jamMulai ?? event.tanggal;
                final peserta = event.targetPeserta.isEmpty
                    ? 'Belum ada peserta'
                    : '${event.targetPeserta.length} peserta diharapkan';
                final location = (event.lokasi ?? '').trim().isEmpty
                    ? 'Lokasi belum ditentukan'
                    : event.lokasi!.trim();

                return _buildEventCard(
                  headerColor: headerColor,
                  title: event.nama,
                  date: _formatShortDate(event.tanggal),
                  time: _formatTime(timeBase),
                  location: location,
                  participants: peserta,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailView(event: event),
                      ),
                    );
                  },
                );
              }),
            );
          },
        ),
      ],
    );
  }
}