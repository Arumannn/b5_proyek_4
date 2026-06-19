import 'package:flutter/material.dart';

// Import halaman-halaman fitur Anda
import 'package:b5_proyek_4/presentation/views/dashboard/dashboard_view.dart';
import 'package:b5_proyek_4/presentation/views/dashboard/member_home_view.dart';
import 'package:b5_proyek_4/presentation/views/event/event_list_view.dart';
import 'package:b5_proyek_4/presentation/views/users/member_list_view.dart';
import 'package:b5_proyek_4/presentation/views/laporan/laporan_view.dart';
import 'package:b5_proyek_4/presentation/views/attendance/attendance_history_view.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/domain/permissions/navigation/navigation_permission.dart';
import 'package:b5_proyek_4/domain/permissions/dashboard/dashboard_permission.dart';

// Import CustomBottomNavBar yang baru dibuat
import 'package:b5_proyek_4/presentation/widgets/shared/custom_bottom_nav.dart'; 
import 'package:b5_proyek_4/presentation/views/profile/profile_view.dart'; 

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  late final List<_NavItem> _navItems;

  String get _role =>
      (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _navItems = _buildNavItems(_role);
    _selectedIndex = _navItems.isEmpty ? 0 : _selectedIndex.clamp(0, _navItems.length - 1);
    // Debug: print role and which tabs are visible
    // ignore: avoid_print
    print('[MainLayout] role=$_role navCount=${_navItems.length}');
    // ignore: avoid_print
    print('[MainLayout] showHome=${NavigationPermission.showHomeTab(_role)}, showEvent=${NavigationPermission.showEventTab(_role)}, showUsers=${NavigationPermission.showUsersTab(_role)}, showReports=${NavigationPermission.showReportsTab(_role)}, showHistory=${NavigationPermission.showHistoryTab(_role)}');
  }

  List<_NavItem> _buildNavItems(String role) {
    final items = <_NavItem>[];

    if (NavigationPermission.showHomeTab(role)) {
      items.add(_NavItem(
        page: DashboardPermission.showExecutiveAdmin(role)
            ? const DashboardView()
            : const MemberHomeView(),
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ));
    }

    if (NavigationPermission.showEventTab(role)) {
      items.add(_NavItem(
        page: const EventListView(showBottomNav: false),
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Event',
      ));
    }

    if (NavigationPermission.showUsersTab(role)) {
      items.add(_NavItem(
        page: const MemberListView(showBottomNav: false),
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: 'Anggota',
      ));
    }

    if (NavigationPermission.showReportsTab(role)) {
      items.add(_NavItem(
        page: const LaporanView(showBottomNav: false),
        icon: Icons.description_outlined,
        activeIcon: Icons.description,
        label: 'Laporan',
      ));
    }

    if (NavigationPermission.showHistoryTab(role)) {
      items.add(_NavItem(
        page: AttendanceHistoryView(
          showBottomNav: false,
          nim: AuthController.instance.currentUser.value?.nim ?? '',
        ),
        icon: Icons.access_time,
        activeIcon: Icons.access_time_filled,
        label: 'Riwayat',
      ));
    }

    // Tab Profile untuk semua role
    items.add(_NavItem(
      page: const ProfileView(),
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ));

    // Fallback safety net: some role configs may not resolve permissions
    // correctly on first load. Keep at least Home + Event + Profil visible
    // for non-executive users so they are never dropped into a profile-only UI.
    if (items.length == 1 && role.isNotEmpty) {
      items.insert(0, _NavItem(
        page: const DashboardView(),
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ));
      items.insert(1, _NavItem(
        page: const EventListView(showBottomNav: false),
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Event',
      ));
    }

    return items;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _navItems.map((item) => item.page).toList(growable: false);
    final navItems = _navItems
        .map(
          (item) => BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon),
            label: item.label,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      // IndexedStack menjaga agar saat pindah tab, data di tab sebelumnya tidak ter-reset
      body: IndexedStack(
        index: _navItems.isEmpty ? 0 : _selectedIndex.clamp(0, _navItems.length - 1),
        children: pages.isEmpty ? [const DashboardView()] : pages,
      ),
      bottomNavigationBar: navItems.length >= 2 
        ? CustomBottomNavBar(
            selectedIndex: _selectedIndex.clamp(0, navItems.length - 1),
            onItemTapped: _onItemTapped,
            items: navItems,
          )
        : null,
    );
  }
}

class _NavItem {
  final Widget page;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.page,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}