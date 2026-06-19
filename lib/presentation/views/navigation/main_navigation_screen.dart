import 'package:flutter/material.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/presentation/theme/design_system.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/presentation/views/users/user_management_view.dart';
import 'package:b5_proyek_4/presentation/views/dashboard/dashboard_view.dart';
import 'package:b5_proyek_4/presentation/views/event/event_view.dart';
import 'package:b5_proyek_4/presentation/views/laporan/laporan_view.dart';
import 'package:b5_proyek_4/presentation/views/attendance/attendance_history_view.dart';
import 'package:b5_proyek_4/domain/permissions/navigation/navigation_permission.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Screen list untuk setiap tab
  Widget _buildScreen(int index) {
    final currentUser = AuthController.instance.currentUser.value;
    final role = (currentUser?.role ?? AppConstants.roleMember)
        .trim()
        .toLowerCase();

    final items = _buildNavItems(role);
    if (items.isEmpty) return const DashboardView();
    
    // Fallback if index is out of bounds
    final safeIndex = index < items.length ? index : 0;
    final item = items[safeIndex];
    return item.screenBuilder(currentUser);
  }

  List<_NavItem> _buildNavItems(String role) {
    final List<_NavItem> items = [];

    if (NavigationPermission.showHomeTab(role)) {
      items.add(_NavItem(
        screenBuilder: (_) => const DashboardView(),
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      ));
    }

    if (NavigationPermission.showEventTab(role)) {
      items.add(_NavItem(
        screenBuilder: (_) => const EventView(),
        destination: const NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Event',
        ),
      ));
    }

    if (NavigationPermission.showUsersTab(role)) {
      items.add(_NavItem(
        screenBuilder: (_) => const UserManagementView(),
        destination: const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Anggota',
        ),
      ));
    }

    if (NavigationPermission.showReportsTab(role)) {
      items.add(_NavItem(
        screenBuilder: (_) => const LaporanView(),
        destination: const NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description),
          label: 'Laporan',
        ),
      ));
    }

    if (NavigationPermission.showHistoryTab(role)) {
      items.add(_NavItem(
        screenBuilder: (user) {
          if (user != null) {
            return AttendanceHistoryView(nim: user.nim);
          }
          return const EventView(); // Fallback
        },
        destination: const NavigationDestination(
          icon: Icon(Icons.schedule_outlined),
          selectedIcon: Icon(Icons.schedule),
          label: 'Riwayat',
        ),
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.elevation3,
          ),
          child: NavigationBar(
            height: 72,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _buildNavItems((AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember).trim().toLowerCase())
                .map((e) => e.destination)
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final Widget Function(dynamic user) screenBuilder;
  final NavigationDestination destination;

  _NavItem({
    required this.screenBuilder,
    required this.destination,
  });
}

