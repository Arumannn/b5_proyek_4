// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/controllers/network_status_controller.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/sectioned_list_body.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/white_status_header.dart';
import 'package:b5_proyek_4/domain/controllers/event/event_controller.dart';
import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/empty_state_box.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/alert_banner.dart';
import 'package:b5_proyek_4/domain/enums/status_enums.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    await EventController.instance.loadEvents(force: true);
    final events = HiveService.events.values.toList();
    
    final currentUser = AuthController.instance.currentUser.value;
    final userRole = (currentUser?.role ?? '').trim().toLowerCase();
    
    final isOrganizer = ConfigController.instance.roleMatchesConfiguredName(userRole, AppConstants.roleOrganizer);
    final isMember = ConfigController.instance.roleMatchesConfiguredName(userRole, AppConstants.roleMember);
    
    final targetNim = (isOrganizer || isMember) ? (currentUser?.nim ?? '') : widget.nim;

    // 1. Ambil rekam absensi aktual yang ada di lokal Hive
    final actualRecords = HiveService.attendance.values
        .where((r) => targetNim.isEmpty || r.nim == targetNim)
        .toList();

    final actualEventIds = actualRecords.map((r) => r.eventId).toSet();

    // 2. Buat rekam kehadiran virtual untuk event yang ditargetkan tapi belum dicatat kehadirannya
    final List<AttendanceRecord> virtualRecords = [];
    if (targetNim.isNotEmpty) {
      final now = DateTime.now();
      for (final event in events) {
        if (event.isDeleted) continue;
        if (actualEventIds.contains(event.eventId)) continue;

        bool isExpected = false;
        if (event.requiresInvitation) {
          final invitations = HiveService.invitations.values
              .where((inv) => inv.eventId == event.eventId && inv.nim == targetNim)
              .toList();
          if (invitations.isNotEmpty) {
            final response = invitations.first.responseStatusEnum;
            if (response == InvitationStatus.approved || response == InvitationStatus.autoApproved) {
              isExpected = true;
            }
          }
        } else {
          if (event.targetPeserta.any((nim) => nim.trim().toLowerCase() == targetNim.trim().toLowerCase())) {
            isExpected = true;
          }
        }

        if (isExpected) {
          String status = 'Belum Absen';
          
          final permissions = HiveService.permissions.values
              .where((p) => p.eventId == event.eventId && p.nim == targetNim)
              .toList();
          if (permissions.isNotEmpty) {
            final p = permissions.first;
            if (p.statusEnum == PermissionStatus.approved) {
              status = p.jenisIzin; // Sakit atau Izin
            } else if (p.statusEnum == PermissionStatus.pending) {
              status = 'Izin Pending';
            } else if (p.statusEnum == PermissionStatus.rejected) {
              final endTime = event.jamSelesai ?? event.tanggalSelesai ?? DateTime(
                event.tanggalMulai.year,
                event.tanggalMulai.month,
                event.tanggalMulai.day,
                23, 59, 59,
              );
              status = now.isAfter(endTime) ? 'Alpha' : 'Belum Absen';
            }
          } else {
            final endTime = event.jamSelesai ?? event.tanggalSelesai ?? DateTime(
              event.tanggalMulai.year,
              event.tanggalMulai.month,
              event.tanggalMulai.day,
              23, 59, 59,
            );
            status = now.isAfter(endTime) ? 'Alpha' : 'Belum Absen';
          }

          virtualRecords.add(AttendanceRecord(
            recordId: 'VIRT-${event.eventId}-$targetNim',
            eventId: event.eventId,
            nim: targetNim,
            timestamp: event.tanggalMulai,
            status: status,
            compositeKey: '${event.eventId}_$targetNim',
          ));
        }
      }
    }

    final records = [...actualRecords, ...virtualRecords]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ekstrak daftar bulan unik (Format: "April 2026")
    final Set<String> monthsSet = {};
    
    // Tambahkan 12 bulan terakhir dari sekarang agar dropdown tidak hanya berisi 1 pilihan
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      monthsSet.add(DateFormat('MMMM yyyy', 'id_ID').format(date));
    }

    for (var r in records) {
      monthsSet.add(DateFormat('MMMM yyyy', 'id_ID').format(r.timestamp));
    }
    
    _availableMonths = monthsSet.toList();
    
    // Urutkan berdasarkan waktu (terbaru paling atas)
    _availableMonths.sort((a, b) {
      try {
        final dateA = DateFormat('MMMM yyyy', 'id_ID').parse(a);
        final dateB = DateFormat('MMMM yyyy', 'id_ID').parse(b);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    // Default ke bulan saat ini jika ada dalam list, atau yang terbaru
    final currentMonthStr = DateFormat('MMMM yyyy', 'id_ID').format(now);
    if (_availableMonths.contains(currentMonthStr)) {
      _selectedMonth.value = currentMonthStr;
    } else if (_availableMonths.isNotEmpty) {
      _selectedMonth.value = _availableMonths.first;
    } else {
      _availableMonths = [currentMonthStr];
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
    return monthRecords.where((r) {
      final s = r.statusEnum;
      if (_selectedFilter.value == 'Hadir') return s == AttendanceStatus.hadir || s == AttendanceStatus.terlambat;
      if (_selectedFilter.value == 'Izin') return s == AttendanceStatus.izin || s == AttendanceStatus.sakit;
      if (_selectedFilter.value == 'Alpha') return s == AttendanceStatus.alpha || s == AttendanceStatus.ditolak;
      return false;
    }).toList();
  }

  // --- LOGIKA STATISTIK ---
  Map<String, int> _getStats(List<AttendanceRecord> monthRecords) {
    // Abaikan status 'Belum Absen' dari total statistik agar tidak menurunkan persentase kehadiran event mendatang
    final completedRecords = monthRecords.where((r) => r.statusEnum != AttendanceStatus.belumAbsen).toList();
    int total = completedRecords.length;
    int hadir = completedRecords.where((r) => r.statusEnum == AttendanceStatus.hadir || r.statusEnum == AttendanceStatus.terlambat).length;
    int izin = completedRecords.where((r) => r.statusEnum == AttendanceStatus.izin || r.statusEnum == AttendanceStatus.sakit).length;
    int alpha = completedRecords.where((r) => r.statusEnum == AttendanceStatus.alpha || r.statusEnum == AttendanceStatus.ditolak).length;
    
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
            onPressed: () => _exportHistory(context),
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: EmptyStateBox(
                    message: 'Tidak ada riwayat untuk filter ini.',
                    icon: Icons.history,
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

  void _exportHistory(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln('No;Nama Event;Tanggal;Waktu;Lokasi;Status');
    
    final records = _filteredRecords;
    for (int i = 0; i < records.length; i++) {
      final r = records[i];
      final event = _eventById[r.eventId];
      final eventName = event?.nama ?? 'Event Tidak Diketahui';
      final location = event?.jenis ?? 'Ruang Kelas';
      final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(r.timestamp);
      final timeStr = DateFormat('HH:mm').format(r.timestamp);
      
      buffer.writeln(
        '${i + 1};$eventName;$dateStr;$timeStr WIB;$location;${r.status}'
      );
    }
    
    _showExportDialog(context, 'Riwayat Absensi', buffer.toString());
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
                        'Sedang memproses & menyusun CSV riwayat',
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
                        'Data riwayat berhasil dikompilasi ke format CSV.',
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
                                    content: Text('Riwayat berhasil disalin ke clipboard!'),
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
      alertBox = const AlertBanner(
        message: 'Tidak hadir tanpa keterangan',
        type: AlertType.error,
      );
    } else if (lowerStatus == 'izin' || lowerStatus == 'sakit') {
      badgeColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFEA580C);
      badgeIcon = Icons.info_outline;
      alertBox = AlertBanner(
        message: 'Alasan:\n${status.toUpperCase()} (Berdasarkan Surat)',
        type: AlertType.warning,
      );
    } else if (lowerStatus == 'izin pending') {
      badgeColor = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFD97706);
      badgeIcon = Icons.hourglass_empty;
      alertBox = const AlertBanner(
        message: 'Pengajuan izin/sakit sedang menunggu persetujuan',
        type: AlertType.warning,
      );
    } else if (lowerStatus == 'izin ditolak') {
      badgeColor = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
      badgeIcon = Icons.cancel_outlined;
      alertBox = const AlertBanner(
        message: 'Pengajuan izin/sakit ditolak',
        type: AlertType.error,
      );
    } else if (lowerStatus == 'belum absen') {
      badgeColor = const Color(0xFFE5E7EB);
      badgeTextColor = const Color(0xFF4B5563);
      badgeIcon = Icons.help_outline;
      alertBox = const AlertBanner(
        message: 'Belum melakukan absensi pada kegiatan ini',
        type: AlertType.info,
      );
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

  // _buildAlertBox removed, using AlertBanner instead
}
