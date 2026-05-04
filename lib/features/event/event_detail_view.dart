import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';

class EventDetailView extends StatelessWidget {
  const EventDetailView({Key? key, required this.event}) : super(key: key);
  final EventModel event;

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
      // Mengatur warna background dasar menjadi abu-abu sangat muda
      backgroundColor: const Color(0xFFF5F7FA), 
      
      // Tahap 1: Membuat AppBar sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.blueAccent, // Warna biru AppBar
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Kegiatan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.nama,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // TODO: Tambahkan fungsi share nanti
            },
          ),
        ],
      ),
      
      // Body sementara kita biarkan kosong dulu sebelum masuk ke Tahap 2
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TAHAP 2: KARTU INFORMASI EVENT ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  // Menambahkan bayangan halus agar kartu terlihat timbul
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.nama,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Memanggil helper function untuk detail
                    _buildInfoRow(
                      icon: Icons.access_time,
                      title: 'Waktu',
                      value: _formatDateTime(event.jamMulai ?? event.tanggal),
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

                    // Kotak khusus untuk Agenda
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB), // Warna biru sangat muda
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agenda Rapat:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAgendaContent(event.deskripsi),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
// --- TAHAP 3: KARTU STATISTIK KEHADIRAN ---
              Row(
                children: [
                  _buildStatCard(
                    iconBgColor: Colors.green.withOpacity(0.15), // Hijau pudar
                    iconColor: Colors.green,
                    icon: Icons.check_circle_outline,
                    count: hadirCount.toString(),
                    label: 'Hadir',
                  ),
                  const SizedBox(width: 12), // Jarak antar kotak
                  _buildStatCard(
                    iconBgColor: Colors.orange.withOpacity(0.15), // Oranye pudar
                    iconColor: Colors.orange,
                    icon: Icons.error_outline,
                    count: izinCount.toString(),
                    label: 'Izin',
                  ),
                  const SizedBox(width: 12), // Jarak antar kotak
                  _buildStatCard(
                    iconBgColor: Colors.red.withOpacity(0.15), // Merah pudar
                    iconColor: Colors.red,
                    icon: Icons.cancel_outlined,
                    count: alphaCount.toString(),
                    label: 'Alpha',
                  ),
                ],
              ),
              const SizedBox(height: 24),
// --- TAHAP 4: DAFTAR KEHADIRAN ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Judul dan Tombol Export
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
                            foregroundColor: Colors.blueAccent, // Warna biru
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (records.isEmpty)
                      Text(
                        'Belum ada kehadiran tercatat.',
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    else
                      ...records.map((record) {
                        final member = memberByNim[record.nim];
                        final name = member?.nama ?? 'Anggota';
                        final initial = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?';
                        final time =
                            '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';
                        final statusLower = record.status.toLowerCase();
                        final isHadir =
                            statusLower.contains('hadir') ||
                            statusLower.contains('terlambat');
                        final isIzin =
                            statusLower.contains('izin') ||
                            statusLower.contains('sakit');
                        final statusColor = isHadir
                            ? Colors.green[700]!
                            : (isIzin
                                ? Colors.orange[800]!
                                : Colors.red[700]!);
                        final statusBgColor = isHadir
                            ? Colors.green.withOpacity(0.15)
                            : (isIzin
                                ? Colors.orange.withOpacity(0.15)
                                : Colors.red.withOpacity(0.15));

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
            ],
          ),
        ),
      ),
    );
  }
  // Fungsi bantuan untuk membuat baris ikon, judul, dan nilai (Waktu, Lokasi, Peserta)
  Widget _buildInfoRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Agar ikon dan teks sejajar di atas
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
                  fontWeight: FontWeight.w600, // Semi-bold agar nilai lebih menonjol
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  // Fungsi bantuan untuk membuat kotak statistik (Hadir, Izin, Alpha)
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lingkaran background untuk Icon
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            // Angka Statistik
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Label Teks (Hadir/Izin/Alpha)
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
  // Fungsi bantuan untuk membuat baris nama peserta
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
      margin: const EdgeInsets.only(bottom: 12.0), // Jarak antar peserta
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), // Warna abu-abu sangat muda untuk latar tiap peserta
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          // Lingkaran Inisial
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
          
          // Nama dan NIM
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
          
          // Label Status dan Jam
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20.0), // Membuat label oval
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
              // Hanya tampilkan jam jika statusnya bukan Alpha/Izin yang kosong
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