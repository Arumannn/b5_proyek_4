import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../../core/utils/network_status_controller.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../widgets/white_status_header.dart';
import '../../core/enums/status_enums.dart';

class LaporanView extends StatefulWidget {
  final bool showBottomNav;

  const LaporanView({super.key, this.showBottomNav = true});

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  String timeFilter = 'Bulan Ini';
  String typeFilter = 'Semua Event';

  final List<String> timeFilters = ['Minggu Ini', 'Bulan Ini', 'Semester Ini', 'Tahun Ini'];
  final List<String> typeFilters = ['Semua Event', 'Event Utama', 'Sub-Event'];

  bool _isLoading = true;
  List<EventModel> _allEvents = [];
  List<AttendanceRecord> _allRecords = [];
  int _totalMembers = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulate slight delay for loading UX
    await Future.delayed(const Duration(milliseconds: 300));
    
    _allEvents = HiveService.events.values.toList();
    _allRecords = HiveService.attendance.values.toList();
    _totalMembers = HiveService.members.length;
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<EventModel> get _filteredEvents {
    final now = DateTime.now();
    return _allEvents.where((e) {
      // Filter Waktu
      bool matchTime = false;
      if (timeFilter == 'Minggu Ini') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        matchTime = e.tanggalMulai.isAfter(startOfWeek) || e.tanggalMulai.isAtSameMomentAs(startOfWeek);
      } else if (timeFilter == 'Bulan Ini') {
        matchTime = e.tanggalMulai.year == now.year && e.tanggalMulai.month == now.month;
      } else if (timeFilter == 'Semester Ini') {
        final isFirstSemester = now.month <= 6;
        matchTime = e.tanggalMulai.year == now.year && (isFirstSemester ? e.tanggalMulai.month <= 6 : e.tanggalMulai.month > 6);
      } else if (timeFilter == 'Tahun Ini') {
        matchTime = e.tanggalMulai.year == now.year;
      }

      // Filter Jenis
      bool matchType = false;
      if (typeFilter == 'Semua Event') {
        matchType = true;
      } else if (typeFilter == 'Event Utama') {
        matchType = e.parentEventId == null;
      } else if (typeFilter == 'Sub-Event') {
        matchType = e.parentEventId != null;
      }

      return matchTime && matchType;
    }).toList()..sort((a, b) => b.tanggalMulai.compareTo(a.tanggalMulai));
  }

  List<Map<String, dynamic>> get reportData {
    return _filteredEvents.map((e) {
      final records = _allRecords.where((r) => r.eventId == e.eventId).toList();
      final hadir = records.where((r) => r.statusEnum == AttendanceStatus.hadir || r.statusEnum == AttendanceStatus.terlambat).length;
      final izin = records.where((r) => r.statusEnum == AttendanceStatus.izin || r.statusEnum == AttendanceStatus.sakit).length;
      final alpha = _totalMembers - (hadir + izin);

      return {
        'id': e.eventId,
        'title': e.nama,
        'date': DateFormat('dd MMM yyyy').format(e.tanggalMulai),
        'type': e.parentEventId == null ? 'Event Utama' : 'Sub-Event',
        'hadir': hadir,
        'izin': izin,
        'alpha': alpha < 0 ? 0 : alpha, // prevent negative if records > total members somehow
      };
    }).toList();
  }

  Map<String, String> get _summaryStats {
    final reports = reportData;
    if (reports.isEmpty) {
      return {'avgHadir': '0%', 'totalEvent': '0', 'avgIzin': '0%'};
    }

    int totalHadir = 0;
    int totalIzin = 0;
    int maxPossible = reports.length * _totalMembers;

    for (var r in reports) {
      totalHadir += (r['hadir'] as int);
      totalIzin += (r['izin'] as int);
    }

    if (maxPossible == 0) return {'avgHadir': '0%', 'totalEvent': reports.length.toString(), 'avgIzin': '0%'};

    final avgHadir = (totalHadir / maxPossible * 100).round();
    final avgIzin = (totalIzin / maxPossible * 100).round();

    return {
      'avgHadir': '$avgHadir%',
      'totalEvent': reports.length.toString(),
      'avgIzin': '$avgIzin%',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WhiteStatusHeader(
        title: 'Laporan Kehadiran',
        subtitle: 'Analisis partisipasi anggota',
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
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
          SliverToBoxAdapter(
            child: _buildRingkasanLaporan(),
          ),
          SliverToBoxAdapter(
            child: _buildFilterOptions(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return _buildListHeader();
                  }
                  if (reportData.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'Belum ada event yang sesuai dengan filter.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  final report = reportData[index - 1];
                  return _buildReportCard(report);
                },
                childCount: reportData.isEmpty ? 2 : reportData.length + 1,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    ),
    );
  }

  Widget _buildRingkasanLaporan() {
    final stats = _summaryStats;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ringkasan Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.bar_chart, color: Colors.blue[600], size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue[200]!,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'RATA-RATA HADIR',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white70, letterSpacing: 0.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        stats['avgHadir']!,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('TOTAL EVENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text(stats['totalEvent']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[100]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('RATA-RATA IZIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[600])),
                              Text(stats['avgIzin']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'FILTER WAKTU',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timeFilters.map((f) {
                final isSelected = timeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => timeFilter = f),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? Colors.blue[600]! : Colors.grey[300]!),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'JENIS EVENT',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: typeFilters.map((f) {
                final isSelected = typeFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => setState(() => typeFilter = f),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple[600] : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? Colors.purple[600]! : Colors.grey[300]!),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
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
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'DETAIL PER EVENT',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937), letterSpacing: 0.5),
          ),
          InkWell(
            onTap: () => _exportRecap(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.download, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Export',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report['title'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Text(
            '${report['date']} • ${report['type']}',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox('HADIR', report['hadir'].toString(), Colors.green),
              const SizedBox(width: 8),
              _buildStatBox('IZIN', report['izin'].toString(), Colors.orange),
              const SizedBox(width: 8),
              _buildStatBox('ALPHA', report['alpha'].toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color[100]!),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color[600]),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color[700]),
            ),
          ],
        ),
      ),
    );
  }

  void _exportRecap(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('No;Nama Event;Tanggal;Jenis;Hadir;Izin;Alpha');
    
    final data = reportData;
    for (int i = 0; i < data.length; i++) {
      final r = data[i];
      buffer.writeln(
        '${i + 1};${r['title']};${r['date']};${r['type']};${r['hadir']};${r['izin']};${r['alpha']}'
      );
    }
    
    _showExportDialog(context, 'Rekap Kehadiran', buffer.toString());
  }

  void _showExportDialog(BuildContext context, String title, String csvContent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        double progress = 0.0;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (progress == 0.0) {
              Future.doWhile(() async {
                await Future.delayed(const Duration(milliseconds: 150));
                if (!dialogContext.mounted) return false;
                setDialogState(() {
                  progress += 0.1;
                  if (progress >= 1.0) {
                    progress = 1.0;
                  }
                });
                return progress < 1.0;
              });
            }

            final isFinished = progress >= 1.0;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFinished) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Mengekspor data... ${(progress * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sedang memproses & menyusun CSV rekap',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '$title Berhasil!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Data rekap berhasil dikompilasi ke format CSV.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 100,
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            csvContent,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Color(0xFF475569)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Tutup', style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: csvContent));
                                if (!context.mounted) return;
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rekap berhasil disalin ke clipboard!'),
                                    backgroundColor: Color(0xFF16A34A),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Salin CSV'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}