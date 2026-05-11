/// Main Navigation Screen dengan Bottom Navigation Bar
/// Mengikuti referensi UI HIMAKOM Attendance
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/design_system.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../dashboard/dashboard_view.dart';
import '../event/event_view.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/attendance_history_view.dart';

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

    switch (index) {
      case 0:
        return const DashboardView();
      case 1:
        return const EventView();
      case 2:
        return const UserManagementView();
      case 3:
        // Laporan/Reports - gunakan AttendanceRecapView
        return const AttendanceRecapView();
      case 4:
        // Riwayat - gunakan AttendanceHistoryView (jika member)
        if (role == AppConstants.roleMember) {
          final user = currentUser;
          if (user != null) {
            return AttendanceHistoryView(
              memberId: user.memberId,
              nim: user.nim,
            );
          }
        }
        // Fallback untuk non-member
        return const EventView();
      default:
        return const DashboardView();
    }
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'Kegiatan',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Anggota',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: 'Laporan',
              ),
              NavigationDestination(
                icon: Icon(Icons.schedule_outlined),
                selectedIcon: Icon(Icons.schedule),
                label: 'Riwayat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
