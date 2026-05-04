// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/event_model.dart';

class EventDetailView extends StatelessWidget {
const EventDetailView({Key? key, required this.event}) : super(key: key);  
final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mengatur warna background dasar menjadi abu-abu sangat muda
      backgroundColor: const Color(0xFFF5F7FA), 
      
      // Tahap 1: Membuat AppBar sesuai desain
      appBar: AppBar(
        backgroundColor: Colors.blueAccent, // Warna biru AppBar
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Kegiatan',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Rapat Koordinasi Pengurus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
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
                    const Text(
                      'Rapat Koordinasi Pengurus',
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
                      value: '24 April 2026, 14:00 - 16:00 WIB',
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi',
                      value: 'Ruang Seminar Informatika, Lantai 3',
                    ),
                    const SizedBox(height: 16),

                    _buildInfoRow(
                      icon: Icons.people_outline,
                      title: 'Peserta',
                      value: '52 anggota diundang',
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agenda Rapat:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pembahasan rencana kegiatan semester depan, evaluasi kinerja divisi, dan koordinasi event tahunan HIMAKOM.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4, // Memberi jarak antar baris teks agar nyaman dibaca
                            ),
                          ),
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
                    count: '6',
                    label: 'Hadir',
                  ),
                  const SizedBox(width: 12), // Jarak antar kotak
                  _buildStatCard(
                    iconBgColor: Colors.orange.withOpacity(0.15), // Oranye pudar
                    iconColor: Colors.orange,
                    icon: Icons.error_outline,
                    count: '1',
                    label: 'Izin',
                  ),
                  const SizedBox(width: 12), // Jarak antar kotak
                  _buildStatCard(
                    iconBgColor: Colors.red.withOpacity(0.15), // Merah pudar
                    iconColor: Colors.red,
                    icon: Icons.cancel_outlined,
                    count: '1',
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

                    // Daftar Peserta memanggil helper function
                    _buildAttendeeItem(
                      initial: 'A',
                      avatarColor: Colors.blueAccent,
                      name: 'Ahmad Fauzi',
                      nim: 'NIM: 2101001',
                      status: 'Hadir',
                      statusTextColor: Colors.green[700]!,
                      statusBgColor: Colors.green.withOpacity(0.15),
                      time: '14:02',
                    ),
                    _buildAttendeeItem(
                      initial: 'S',
                      avatarColor: Colors.blueAccent,
                      name: 'Siti Nurhaliza',
                      nim: 'NIM: 2101002',
                      status: 'Hadir',
                      statusTextColor: Colors.green[700]!,
                      statusBgColor: Colors.green.withOpacity(0.15),
                      time: '14:05',
                    ),
                    _buildAttendeeItem(
                      initial: 'B',
                      avatarColor: Colors.blueAccent,
                      name: 'Budi Santoso',
                      nim: 'NIM: 2101003',
                      status: 'Izin',
                      statusTextColor: Colors.orange[800]!,
                      statusBgColor: Colors.orange.withOpacity(0.15),
                      time: '', // Kosong karena izin
                    ),
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