import 'package:flutter/material.dart';

// Import halaman-halaman fitur Anda
import 'dashboard_view.dart';
import '../event/event_list_view.dart';
import '../member/member_list_view.dart';
import '../laporan/laporan_view.dart';
import '../attendance/attendance_history_view.dart';
import '../auth/auth_controller.dart';

// Import CustomBottomNavBar yang baru dibuat
import '../../widgets/custom_bottom_nav.dart'; 

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Daftar halaman yang akan ditampilkan sesuai urutan Bottom Nav
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // 0: Home / Dashboard
      const DashboardView(),
      
      // 1: Kegiatan
      const EventListView(showBottomNav: false),
      
      // 2: Anggota
      const MemberListView(showBottomNav: false),
      
      // 3: Laporan
      const LaporanView(showBottomNav: false),
      
      // 4: Riwayat
      AttendanceHistoryView(
        showBottomNav: false,
        nim: AuthController.instance.currentUser.value?.nim ?? '',
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga agar saat pindah tab, data di tab sebelumnya tidak ter-reset
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}