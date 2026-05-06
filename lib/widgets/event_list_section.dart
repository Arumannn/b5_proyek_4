import 'package:flutter/material.dart';
import '../features/event/event_controller.dart';
import '../features/event/event_detail_view.dart';
import '../models/event_model.dart';
import '../core/services/hive_service.dart';
import '../models/attendance_record.dart';

class EventListSection extends StatefulWidget {
  const EventListSection({Key? key}) : super(key: key);

  @override
  State<EventListSection> createState() => _EventListSectionState();
}

class _EventListSectionState extends State<EventListSection> {
  // 0 = Kegiatan Terakhir, 1 = Mendatang
  int _activeTabIndex = 0; 
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

  // --- LOGIC FOR ATTENDANCE CARDS ---
  List<AttendanceRecord> _attendanceForEvent(String eventId) {
    return HiveService.attendance.values
        .where((record) => record.eventId == eventId)
        .toList(growable: false);
  }

  int _targetCount(EventModel event, int presentCount) {
    final target = event.targetPeserta.length;
    if (target > 0) return target;
    return presentCount > 0 ? presentCount : 1;
  }

  String _formatDateFull(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatTimeOptional(DateTime? value) {
    if (value == null) return '--:--';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Color _eventStatusColor(EventModel event) {
    return event.statusEvent == 'Selesai' ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
  }

  Color _eventStatusBgColor(EventModel event) {
    return event.statusEvent == 'Selesai' ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
  }

  String _eventLocation(EventModel event) {
    final raw = event.deskripsi?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Lokasi belum diatur';
  }

  Widget _buildAttendanceEventCard(BuildContext context, EventModel event) {
    final attendance = _attendanceForEvent(event.eventId);
    final presentCount = attendance
        .where((record) => record.status.toLowerCase().contains('hadir'))
        .length;
    final targetCount = _targetCount(event, presentCount);
    final attendancePercent =
        targetCount == 0 ? 0.0 : (presentCount / targetCount).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => EventDetailView(event: event)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.nama,
                      style: const TextStyle(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF283548),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _eventStatusBgColor(event),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 17,
                          color: _eventStatusColor(event),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          event.statusEvent,
                          style: TextStyle(
                            color: _eventStatusColor(event),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_formatDateFull(event.tanggalMulai)} • ${_formatTimeOptional(event.jamMulai)} WIB',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _eventLocation(event),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Text(
                    '$presentCount/$targetCount hadir',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Kehadiran',
                    style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
                  ),
                  const SizedBox(width: 14),
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
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(attendancePercent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 31 / 2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk membuat Kartu Event yang warna-warni
  Widget _buildColoredEventCard({
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
              final isPast = event.tanggalMulai.isBefore(now);
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
                
                // Jika Kegiatan Terakhir (tab 0), tampilkan card dengan bar kehadiran
                if (_activeTabIndex == 0) {
                  return _buildAttendanceEventCard(context, event);
                }

                // Jika Mendatang (tab 1), tampilkan card berwarna
                final headerColor = _headerColors[index % _headerColors.length];
                final timeBase = event.jamMulai ?? event.tanggalMulai;
                final peserta = event.targetPeserta.isEmpty
                    ? 'Belum ada peserta'
                    : '${event.targetPeserta.length} peserta diharapkan';
                final location = (event.lokasi ?? '').trim().isEmpty
                    ? 'Lokasi belum ditentukan'
                    : event.lokasi!.trim();

                return _buildColoredEventCard(
                  headerColor: headerColor,
                  title: event.nama,
                  date: _formatShortDate(event.tanggalMulai),
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