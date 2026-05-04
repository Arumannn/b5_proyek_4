import 'package:flutter/material.dart';
import '../features/event/event_list_view.dart';
import '../features/laporan/laporan_view.dart';
import '../features/member/member_list_view.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  // Helper function untuk membuat menu item agar kodenya tidak berulang
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Sudut membulat
        ),
        // Jika terpilih, beri warna latar biru sangat muda. Jika tidak, transparan.
        tileColor: isSelected ? const Color(0xFFF0F5FF) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.blueGrey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.blueGrey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER DRAWER (Teks Menu & Tombol Close) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937), // Warna abu-abu kehitaman pekat
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () {
                      Navigator.pop(context); // Menutup drawer
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),

            // --- DAFTAR MENU ---
            // Kita gunakan Expanded agar daftar menu mengisi ruang kosong
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    icon: Icons.show_chart, // Menggunakan icon grafik
                    title: 'Dashboard',
                    isSelected: true, // Set true agar menyala biru
                    onTap: () {
                      // TODO: Navigasi ke Dashboard
                      Navigator.pop(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'Kegiatan',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EventListView(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.people_outline,
                    title: 'Anggota',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemberListView(),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Laporan',
                    isSelected: false,
                    onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LaporanView()),
                        );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history,
                    title: 'Riwayat',
                    isSelected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // --- BOTTOM PROFILE SECTION ---
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // Warna latar abu-abu sangat muda
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 20,
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin HIMAKOM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pengurus Inti',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}