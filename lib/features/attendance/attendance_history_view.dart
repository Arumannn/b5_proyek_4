import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/hive_service.dart';
import '../../features/event/event_controller.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';

class AttendanceHistoryView extends StatefulWidget {
  final String nim;
  const AttendanceHistoryView({super.key, required this.nim});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  bool _isLoading = true;
  List<AttendanceRecord> _allRecords = [];
  Map<String, EventModel> _eventById = {};

  // UI State Controllers (Tanpa setState untuk filter)
  final ValueNotifier<String> _selectedMonth = ValueNotifier<String>('');
  final ValueNotifier<String> _selectedFilter = ValueNotifier<String>('Semua');
  
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    await EventController.instance.loadEvents(force: true);
    final events = HiveService.events.values.toList();
    
    // Tarik dan urutkan rekam absensi milik user ini[cite: 18, 19]
    final records = HiveService.attendance.values
        .where((r) => r.nim == widget.nim)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ekstrak daftar bulan unik (Format: "April 2026")
    final Set<String> monthsSet = {};
    for (var r in records) {
      monthsSet.add(DateFormat('MMMM yyyy', 'id_ID').format(r.timestamp));
    }
    
    _availableMonths = monthsSet.toList();
    // Default ke bulan pertama di list (terbaru) atau bulan saat ini
    if (_availableMonths.isNotEmpty) {
      _selectedMonth.value = _availableMonths.first;
    } else {
      _availableMonths = [DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())];
      _selectedMonth.value = _availableMonths.first;
    }

    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _eventById = {for (final e in events) e.eventId: e};
      _isLoading = false;
    });
  }

  // --- LOGIKA FILTERING ---
  List<AttendanceRecord> get _recordsForSelectedMonth {
    return _allRecords.where((r) {
      final monthStr = DateFormat('MMMM yyyy', 'id_ID').format(r.timestamp);
      return monthStr == _selectedMonth.value;
    }).toList();
  }

  List<AttendanceRecord> get _filteredRecords {
    final monthRecords = _recordsForSelectedMonth;
    if (_selectedFilter.value == 'Semua') return monthRecords;
    return monthRecords.where((r) => r.status.toLowerCase() == _selectedFilter.value.toLowerCase()).toList();
  }

  // --- LOGIKA STATISTIK ---
  Map<String, int> _getStats(List<AttendanceRecord> monthRecords) {
    int total = monthRecords.length;
    int hadir = monthRecords.where((r) => r.status.toLowerCase() == 'hadir' || r.status.toLowerCase() == 'terlambat').length;
    int izin = monthRecords.where((r) => r.status.toLowerCase() == 'izin' || r.status.toLowerCase() == 'sakit').length;
    int alpha = monthRecords.where((r) => r.status.toLowerCase() == 'alpha').length;
    
    return {'total': total, 'hadir': hadir, 'izin': izin, 'alpha': alpha};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Latar belakang abu terang
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCards(),
                _buildFilterChips(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    child: _buildRecordList(),
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1D4ED8), // Biru Header
      elevation: 0,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Kehadiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          Text('History absensi Anda', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined),
          onPressed: () {
            // TODO: Implementasi Export PDF di Week selanjutnya
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B66E0), // Biru dropdown yang sedikit lebih terang
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _selectedMonth,
              builder: (context, currentMonth, child) {
                return DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    icon: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    ),
                    value: currentMonth.isNotEmpty ? currentMonth : null,
                    items: _availableMonths.map((month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, 
                                size: 18, 
                                color: currentMonth == month ? Colors.white : Colors.black87
                              ),
                              const SizedBox(width: 12),
                              Text(
                                month,
                                style: TextStyle(
                                  color: currentMonth == month ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectedMonth.value = val;
                        _selectedFilter.value = 'Semua'; // Reset filter saat ganti bulan
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return _availableMonths.map<Widget>((String item) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(item, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedMonth,
      builder: (context, _, __) {
        final stats = _getStats(_recordsForSelectedMonth);
        final percent = stats['total']! == 0 ? 0 : ((stats['hadir']! / stats['total']!) * 100).round();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Kartu Biru - Tingkat Kehadiran
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Tingkat Kehadiran', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Kartu Hijau - Total Hadir
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text('Total Hadir', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${stats['hadir']}/${stats['total']}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedMonth,
      builder: (context, _, __) {
        final stats = _getStats(_recordsForSelectedMonth);
        
        return ValueListenableBuilder<String>(
          valueListenable: _selectedFilter,
          builder: (context, selected, _) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _customChip('Semua', stats['total']!, selected == 'Semua', Colors.grey.shade600),
                  _customChip('Hadir', stats['hadir']!, selected == 'Hadir', Colors.grey.shade600), // Default sketch color
                  _customChip('Izin', stats['izin']!, selected == 'Izin', const Color(0xFFEA580C)), // Orange
                  _customChip('Alpha', stats['alpha']!, selected == 'Alpha', const Color(0xFFDC2626)), // Red
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _customChip(String label, int count, bool isSelected, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => _selectedFilter.value = label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordList() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedFilter,
      builder: (context, _, __) {
        final records = _filteredRecords;

        if (records.isEmpty) {
          return const Center(
            child: Text('Tidak ada riwayat untuk filter ini.', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final event = _eventById[record.eventId];
            final eventName = event?.nama ?? 'Event Tidak Diketahui';
            
            // Dummy Data untuk menyesuaikan sketsa
            final location = event?.jenis ?? 'Ruang Kelas'; // Menggunakan 'jenis' sebagai dummy lokasi[cite: 7]
            final timeStr = DateFormat('HH:mm').format(record.timestamp);
            final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(record.timestamp);
            
            return _RecordCard(
              eventName: eventName,
              date: dateStr,
              time: '$timeStr WIB',
              location: location,
              status: record.status,
              duration: '2 jam', // Dummy
            );
          },
        );
      },
    );
  }
}

// Komponen Kartu Detail Absensi
class _RecordCard extends StatelessWidget {
  final String eventName;
  final String date;
  final String time;
  final String location;
  final String status;
  final String duration;

  const _RecordCard({
    required this.eventName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    // Styling based on status
    Color badgeColor;
    Color badgeTextColor;
    IconData badgeIcon;
    Widget? alertBox;

    final lowerStatus = status.toLowerCase();
    
    if (lowerStatus == 'alpha') {
      badgeColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeIcon = Icons.cancel_outlined;
      alertBox = _buildAlertBox(badgeColor, badgeTextColor, badgeIcon, 'Tidak hadir tanpa keterangan');
    } else if (lowerStatus == 'izin' || lowerStatus == 'sakit') {
      badgeColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFEA580C);
      badgeIcon = Icons.info_outline;
      alertBox = _buildAlertBox(badgeColor, badgeTextColor, badgeIcon, 'Alasan:\n${status.toUpperCase()} (Berdasarkan Surat)');
    } else if (lowerStatus == 'terlambat') {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      badgeIcon = Icons.timer_outlined;
    } else { // Hadir
      badgeColor = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
      badgeIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Nama Event & Badge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    eventName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(color: badgeTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info Baris (Tanggal, Waktu, Lokasi)
            _buildInfoRow(Icons.calendar_today_outlined, date),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, time),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, location),
            
            // Alert Box (Jika Izin/Alpha)
            if (alertBox != null) ...[
              const SizedBox(height: 16),
              alertBox,
            ],
            
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            // Footer (Durasi)
            Text('Durasi: $duration', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 14)),
      ],
    );
  }

  Widget _buildAlertBox(Color bgColor, Color textColor, IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}