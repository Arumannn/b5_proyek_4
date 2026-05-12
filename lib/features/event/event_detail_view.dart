import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/gradient_header.dart';

class EventDetailView extends StatelessWidget {
  final EventModel event;
  final String userRole;

  const EventDetailView({
    super.key, 
    required this.event,
    required this.userRole,
  });

  String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy, $hh:$min WIB';
  }

  String _eventLocation() {
    final lokasi = event.lokasi?.trim();
    if (lokasi != null && lokasi.isNotEmpty) return lokasi;
    return 'Lokasi belum diatur';
  }

  List<AttendanceRecord> _attendanceRecords() {
    return HiveService.attendance.values
        .where((r) => r.eventId == event.eventId)
        .toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Map<String, MemberModel> _memberByNim() {
    return {
      for (final m in HiveService.members.values) m.nim: m,
    };
  }

  int _countStatus(List<AttendanceRecord> records, List<String> tokens) {
    return records.where((r) {
      final value = r.status.toLowerCase();
      return tokens.any((t) => value.contains(t));
    }).length;
  }

  Widget _buildAgendaContent(String? raw) {
    final normalized = (raw ?? '').trim();
    if (normalized.isEmpty) {
      return Text(
        'Belum ada agenda.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          height: 1.4,
        ),
      );
    }

    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isBullet = line.startsWith('- ') ||
            line.startsWith('* ') ||
            line.startsWith('• ');
        final text = isBullet ? line.substring(2).trim() : line;

        if (!isBullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Icon(Icons.circle, size: 6, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _attendanceRecords();
    final memberByNim = _memberByNim();
    final hadirCount = _countStatus(records, ['hadir', 'terlambat']);
    final izinCount = _countStatus(records, ['izin', 'sakit']);
    final alphaCount = _countStatus(records, ['alpha']);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD), 
      appBar: GradientHeader(
        title: 'Detail Kegiatan',
        subtitle: event.nama,
        actions: [
          IconButton(
            tooltip: 'Bagikan',
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Tambahkan fungsi share nanti
            },
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Informasi Event dengan Accent Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Accent bar
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Text(
                            event.nama,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info rows with better styling
                    _buildInfoRow(
                      icon: Icons.access_time_outlined,
                      title: 'Waktu',
                      value: _formatDateTime(event.jamMulai ?? event.tanggalMulai),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      value: _eventLocation(),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      icon: Icons.people_outline,
                      title: 'Peserta',
                      value: event.targetPeserta.isEmpty
                          ? 'Semua anggota'
                          : '${event.targetPeserta.length} anggota diundang',
                    ),
                    const SizedBox(height: 24),

                    // Agenda section with refined styling
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 16,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Agenda Rapat:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAgendaContent(event.deskripsi),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Kartu Statistik Kehadiran - Enhanced Style
              Row(
                children: [
                  _buildStatCard(
                    iconBgColor: const Color(0x2622C55E),
                    iconColor: const Color(0xFF22C55E),
                    icon: Icons.check_circle_outline,
                    count: hadirCount.toString(),
                    label: 'Hadir',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    iconBgColor: const Color(0x26F59E0B),
                    iconColor: const Color(0xFFF59E0B),
                    icon: Icons.error_outline,
                    count: izinCount.toString(),
                    label: 'Izin',
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    iconBgColor: const Color(0x26EF4444),
                    iconColor: const Color(0xFFEF4444),
                    icon: Icons.cancel_outlined,
                    count: alphaCount.toString(),
                    label: 'Alpha',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Daftar Kehadiran
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Kehadiran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Fungsi Export
                          },
                          icon: const Icon(Icons.download_outlined, size: 18),
                          label: const Text('Export'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (records.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Belum ada kehadiran tercatat.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      )
                    else
                      ...records.map((record) {
                        final member = memberByNim[record.nim];
                        final name = member?.nama ?? 'Anggota';
                        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                        final time = '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
                        final statusLower = record.status.toLowerCase();
                        final isHadir = statusLower.contains('hadir') || statusLower.contains('terlambat');
                        final isIzin = statusLower.contains('izin') || statusLower.contains('sakit');
                        final statusColor = isHadir
                            ? const Color(0xFF22C55E)
                            : (isIzin ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
                        final statusBgColor = isHadir
                            ? const Color(0x2622C55E)
                            : (isIzin ? const Color(0x26F59E0B) : const Color(0x26EF4444));

                        return _buildAttendeeItem(
                          initial: initial,
                          avatarColor: Colors.blueAccent,
                          name: name,
                          nim: 'NIM: ${record.nim}',
                          status: record.status,
                          statusTextColor: statusColor,
                          statusBgColor: statusBgColor,
                          time: time,
                        );
                      }),
                  ],
                ),
              ), 
              const SizedBox(height: 24),

              // Kontrol berdasarkan Role
              if (userRole == AppConstants.roleExecutive)
                _buildExecutiveControls()
              else if (userRole == AppConstants.roleManager || userRole == AppConstants.roleOrganizer)
                const Text('Area Manager/Organizer (Pantauan Undangan)')
              else
                const Text('Area Member (Status Undangan Saya)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExecutiveControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Kontrol Eksekutif',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Logika batalkan/hapus kegiatan
            },
            icon: const Icon(Icons.cancel, color: Colors.white),
            label: const Text('Batalkan Kegiatan Ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String title, 
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.grey[500]),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required Color iconBgColor,
    required Color iconColor,
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeeItem({
    required String initial,
    required Color avatarColor,
    required String name,
    required String nim,
    required String status,
    required Color statusTextColor,
    required Color statusBgColor,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: avatarColor,
            radius: 20,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nim,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}