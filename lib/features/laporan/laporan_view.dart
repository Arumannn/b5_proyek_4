import 'package:flutter/material.dart';

class LaporanView extends StatefulWidget {
  final bool showBottomNav;

  const LaporanView({Key? key, this.showBottomNav = true}) : super(key: key);

  @override
  State<LaporanView> createState() => _LaporanViewState();
}

class _LaporanViewState extends State<LaporanView> {
  // Variabel untuk menyimpan tab mana yang sedang aktif
  // 0 = Minggu Ini, 1 = Bulan Ini, 2 = Tahun Ini
  int _activeTabIndex = 1;

  // Helper function untuk membuat tombol Tab Filter
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
            color: isActive ? Colors.blueAccent : Colors.grey[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.blueGrey[700],
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Abu-abu sangat muda
      
      // --- TAHAP 1: APPBAR ---
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan Kehadiran',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Analisis & statistik kegiatan',
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
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Fungsi download laporan
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TAHAP 1.5: TAB FILTER BLOK PUTIH ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildTabButton('Minggu Ini', 0),
                  const SizedBox(width: 8),
                  _buildTabButton('Bulan Ini', 1),
                  const SizedBox(width: 8),
                  _buildTabButton('Tahun Ini', 2),
                ],
              ),
            ),
            
            // Jarak sebelum masuk ke konten grid statistik
            const SizedBox(height: 16),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
// --- TAHAP 2: KOTAK STATISTIK GRID ---
                  Column(
                    children: [
                      // Baris Pertama (Total Kegiatan & Rata-rata Hadir)
                      Row(
                        children: [
                          _buildGridStatCard(
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.blueAccent,
                            iconBgColor: Colors.blueAccent.withOpacity(0.1),
                            value: '42',
                            label: 'Total Kegiatan',
                          ),
                          const SizedBox(width: 16), // Jarak antar kolom
                          _buildGridStatCard(
                            icon: Icons.trending_up,
                            iconColor: Colors.green,
                            iconBgColor: Colors.green.withOpacity(0.1),
                            value: '87%',
                            label: 'Rata-rata Hadir',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // Jarak antar baris
                      // Baris Kedua (Total Anggota & Partisipasi)
                      Row(
                        children: [
                          _buildGridStatCard(
                            icon: Icons.people_outline,
                            iconColor: Colors.purpleAccent,
                            iconBgColor: Colors.purpleAccent.withOpacity(0.1),
                            value: '156',
                            label: 'Total Anggota',
                          ),
                          const SizedBox(width: 16),
                          _buildGridStatCard(
                            icon: Icons.bar_chart,
                            iconColor: Colors.orange,
                            iconBgColor: Colors.orange.withOpacity(0.1),
                            value: '92%',
                            label: 'Partisipasi',
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),               
// --- TAHAP 3: TREN KEHADIRAN BULANAN ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tren Kehadiran Bulanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Memanggil helper function untuk setiap bulan
                        _buildTrendItem(
                          month: 'Jan',
                          percentage: 0.85, // 85%
                          percentText: '85%',
                          subtitle: '12 rapat',
                        ),
                        _buildTrendItem(
                          month: 'Feb',
                          percentage: 0.88, // 88%
                          percentText: '88%',
                          subtitle: '10 rapat',
                        ),
                        _buildTrendItem(
                          month: 'Mar',
                          percentage: 0.82, // 82%
                          percentText: '82%',
                          subtitle: '14 rapat',
                        ),
                        _buildTrendItem(
                          month: 'Apr',
                          percentage: 0.87, // 87%
                          percentText: '87%',
                          subtitle: '8 rapat',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24), // Jarak sebelum masuk ke Tahap 4                  
// --- TAHAP 4: ANGGOTA TERAKTIF ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anggota Teraktif',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Memanggil helper function untuk anggota urutan 1
                        _buildActiveMemberItem(
                          rank: '1',
                          avatarColor: Colors.amber, // Warna kuning keemasan
                          name: 'Maya Wijaya',
                          role: 'Medinfo',
                          percentage: '97%',
                          progress: 0.97,
                          progressColor: Colors.greenAccent[700]!, // Warna hijau
                        ),
                        
                        // Kamu bisa menambahkan anggota ke-2, ke-3, dst di bawah sini nanti
                      ],
                    ),
                  ),
                  
                  // Memberikan jarak ekstra di bagian paling bawah agar nyaman saat di-scroll
                  const SizedBox(height: 40),                
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Fungsi bantuan untuk membuat kartu statistik di dalam grid
  Widget _buildGridStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          // Pada desain, terlihat ada garis batas (border) tipis berwarna abu-abu
          border: Border.all(color: Colors.grey.withOpacity(0.2)), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wadah ikon (kotak dengan sudut membulat, bukan lingkaran penuh)
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            // Angka Statistik
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            // Teks Label
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
  // Fungsi bantuan untuk membuat baris grafik tren bulanan
  Widget _buildTrendItem({
    required String month,
    required double percentage, // Nilai dari 0.0 sampai 1.0 untuk panjang bar
    required String percentText,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bagian Kiri: Teks Bulan dan Grafik Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 8),
                // Custom Progress Bar menggunakan Stack & FractionallySizedBox
                Container(
                  height: 8, // Ketebalan grafik bar
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200], // Warna background bar (abu-abu terang)
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft, // Mulai isi dari kiri
                    widthFactor: percentage, // Seberapa panjang bar terisi (0.0 - 1.0)
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent, // Warna bar terisi (biru)
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bagian Kanan: Teks Persentase dan Jumlah Rapat
          Column(
            crossAxisAlignment: CrossAxisAlignment.end, // Rata kanan
            children: [
              Text(
                percentText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Fungsi bantuan untuk membuat baris daftar anggota teraktif
  Widget _buildActiveMemberItem({
    required String rank,
    required Color avatarColor,
    required String name,
    required String role,
    required String percentage,
    required double progress, // 0.0 sampai 1.0
    required Color progressColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Lingkaran Peringkat (Warna Kuning/Emas)
          CircleAvatar(
            backgroundColor: avatarColor,
            radius: 20,
            child: Text(
              rank,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Nama dan Divisi
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
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Persentase dan Mini Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              // Mini Progress Bar di bawah angka persentase
              Container(
                height: 4,
                width: 48, // Lebar statis untuk bar kecil ini
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}