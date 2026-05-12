// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/hive_service.dart';
import '../../core/utils/network_status_controller.dart';
import '../../widgets/sectioned_list_body.dart';
import '../../widgets/white_status_header.dart';
import '../../features/event/event_controller.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';

class AttendanceHistoryView extends StatefulWidget {
  final String nim;
  final bool showBottomNav;
  const AttendanceHistoryView({super.key, required this.nim, this.showBottomNav = true});

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
      backgroundColor: const Color(0xFFF3F7FD),
      appBar: WhiteStatusHeader(
        title: 'Riwayat Kehadiran',
        subtitle: 'History absensi Anda',
        statusBadge: ValueListenableBuilder<bool>(
          valueListenable: NetworkStatusController.instance.isOnline,
          builder: (context, isOnline, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOnline ? const Color(0xFFE8F7EF) : const Color(0xFFFFF3E6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 10,
                    color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isOnline ? 'TERSINKRONISASI' : 'OFFLINE (SIMPAN LOKAL)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Unduh Riwayat',
            icon: const Icon(Icons.download_outlined, color: Color(0xFF111827)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SectionedListBody(
                header: Column(
                  children: [
                    _buildMonthPickerCard(),
                    const SizedBox(height: 14),
                    _buildSummaryCards(),
                  ],
                ),
                searchBar: const SizedBox.shrink(),
                filterArea: _buildFilterChips(),
                listBuilder: (context) => _buildRecordList(),
                emptyState: const SizedBox.shrink(),
                onRefresh: _fetchData,
              ),
      ),
    );
  }

  Widget _buildMonthPickerCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ValueListenableBuilder<String>(
          valueListenable: _selectedMonth,
          builder: (context, currentMonth, child) {
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                value: currentMonth.isNotEmpty ? currentMonth : null,
                items: _availableMonths.map((month) {
                  return DropdownMenuItem<String>(
                    value: month,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: currentMonth == month ? const Color(0xFF2563EB) : Colors.black87,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          month,
                          style: TextStyle(
                            color: currentMonth == month ? const Color(0xFF2563EB) : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _selectedMonth.value = val;
                    _selectedFilter.value = 'Semua';
                  }
                },
                selectedItemBuilder: (BuildContext context) {
                  return _availableMonths.map<Widget>((String item) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedMonth,
      builder: (context, _, _) {
        final stats = _getStats(_recordsForSelectedMonth);
        final percent = stats['total']! == 0 ? 0 : ((stats['hadir']! / stats['total']!) * 100).round();

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                label: 'Tingkat Kehadiran',
                value: '$percent%',
                icon: Icons.trending_up,
                backgroundColor: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
                accentColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                label: 'Total Hadir',
                value: '${stats['hadir']}/${stats['total']}',
                icon: Icons.check_circle_outline,
                backgroundColor: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF16A34A),
                accentColor: const Color(0xFF16A34A),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return ValueListenableBuilder<String>(
      valueListenable: _selectedMonth,
      builder: (context, _, _) {
        final stats = _getStats(_recordsForSelectedMonth);
        
        return ValueListenableBuilder<String>(
          valueListenable: _selectedFilter,
          builder: (context, selected, _) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _customChip('Semua', stats['total']!, selected == 'Semua', const Color(0xFF475569)),
                    _customChip('Hadir', stats['hadir']!, selected == 'Hadir', const Color(0xFF2563EB)),
                    _customChip('Izin', stats['izin']!, selected == 'Izin', const Color(0xFFEA580C)),
                    _customChip('Alpha', stats['alpha']!, selected == 'Alpha', const Color(0xFFDC2626)),
                  ],
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(999),
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
      builder: (context, _, _) {
        final records = _filteredRecords;

        if (records.isEmpty) {
          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.15,
                ),
                child: const Center(
                  child: Text(
                    'Tidak ada riwayat untuk filter ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final event = _eventById[record.eventId];
            final eventName = event?.nama ?? 'Event Tidak Diketahui';
            final location = event?.jenis ?? 'Ruang Kelas';
            final timeStr = DateFormat('HH:mm').format(record.timestamp);
            final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(record.timestamp);

            return _RecordCard(
              eventName: eventName,
              date: dateStr,
              time: '$timeStr WIB',
              location: location,
              status: record.status,
              duration: '2 jam',
              isLast: index == records.length - 1,
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
  final bool isLast;

  const _RecordCard({
    required this.eventName,
    required this.date,
    required this.time,
    required this.location,
    required this.status,
    required this.duration,
    required this.isLast,
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
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    borderRadius: BorderRadius.circular(999),
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
            _buildInfoRow(Icons.calendar_today_outlined, date),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, time),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, location),
            if (alertBox != null) ...[
              const SizedBox(height: 16),
              alertBox,
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(16),
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
