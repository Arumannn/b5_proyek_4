import 'package:flutter/material.dart';
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
        if (_activeTabIndex == 1) ...[
          // Tampilan jika tab "Mendatang" ditekan
          _buildEventCard(
            headerColor: const Color(0xFF3B82F6), // Biru
            title: 'Rapat Mingguan Divisi',
            date: '28 Apr',
            time: '14:00 WIB',
            location: 'Ruang Meeting 2',
            participants: '25 peserta diharapkan',
            onTap: () {
              final event = EventModel(
                eventId: 'rapat_mingguan_divisi',
                nama: 'Rapat Mingguan Divisi',
                jenis: 'Kegiatan',
                tanggal: DateTime(2024, 4, 28, 14, 0),
                createdBy: 'system',
                deskripsi:
                    'Rapat mingguan untuk membahas progres dan rencana kerja divisi.',
                targetPeserta: ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
                jamMulai: DateTime(2024, 4, 28, 14, 0),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(event: event),
                ),
              );
            }
          ),
          _buildEventCard(
            headerColor: const Color(0xFFA855F7), // Ungu
            title: 'Diskusi Proyek Akhir',
            date: '29 Apr',
            time: '10:00 WIB',
            location: 'Lab Komputer 2',
            participants: '15 peserta diharapkan',
            onTap: () {
              final event = EventModel(
                eventId: 'diskusi_proyek_akhir',
                nama: 'Diskusi Proyek Akhir',
                jenis: 'Kegiatan',
                tanggal: DateTime(2024, 4, 29, 10, 0),
                createdBy: 'system',
                deskripsi:
                    'Diskusi untuk mempersiapkan proyek akhir yang akan datang.',
                targetPeserta: ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
                jamMulai: DateTime(2024, 4, 29, 10, 0),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(event: event),
                ),
              );
            }
          ),
          _buildEventCard(
            headerColor: const Color(0xFFF97316), // Oranye
            title: 'Sosialisasi Event Besar',
            date: '30 Apr',
            time: '13:00 WIB',
            location: 'Aula Utama',
            participants: '80 peserta diharapkan',
            onTap: () {
              final event = EventModel(
                eventId: 'sosialisasi_event_besar',
                nama: 'Sosialisasi Event Besar',
                jenis: 'Kegiatan',
                tanggal: DateTime(2024, 4, 30, 13, 0),
                createdBy: 'system',
                deskripsi:
                    'Sosialisasi untuk mempersiapkan event besar yang akan datang.',
                targetPeserta: ['Alice', 'Bob', 'Charlie', 'David', 'Eve'],
                jamMulai: DateTime(2024, 4, 30, 13, 0),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(event: event),
                ),
              );
            }
          ),
        ] else ...[
          // Tampilan jika tab "Kegiatan Terakhir" ditekan
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Belum ada kegiatan terakhir.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ],
    );
  }
}