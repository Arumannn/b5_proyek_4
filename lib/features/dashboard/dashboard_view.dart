import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/attendance_history_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../event/event_view.dart';
import '../event/sub_event_view.dart';
import '../member/member_profile_view.dart';
import '../member/permission_form_view.dart';
import '../member/qr_display_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardMenuItem {
  const _DashboardMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.requireRoles = const <String>[],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder;
  final List<String> requireRoles;

  bool canAccess(String role) {
    if (requireRoles.isEmpty) return true;
    return requireRoles.contains(role);
  }
}

class _DashboardViewState extends State<DashboardView> {
  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await AuthController.instance.logout(context);
    }
  }

  List<_DashboardMenuItem> _buildMenuItems(String role) {
    final currentUser = AuthController.instance.currentUser.value;

    final items = <_DashboardMenuItem>[
      _DashboardMenuItem(
        title: 'Kelola Pengguna',
        subtitle: 'CRUD akun pengguna',
        icon: Icons.groups_2_outlined,
        requireRoles: const [AppConstants.roleAdmin],
        builder: (_) => const UserManagementView(),
      ),
      _DashboardMenuItem(
        title: 'Kelola Event',
        subtitle: 'List, form, dan CRUD event',
        icon: Icons.event_note_outlined,
        requireRoles: const [AppConstants.roleAdmin, AppConstants.roleManager],
        builder: (_) => const EventView(),
      ),
      _DashboardMenuItem(
        title: 'Lihat Event',
        subtitle: 'Read-only daftar event dan detail',
        icon: Icons.event_available_outlined,
        requireRoles: const [AppConstants.roleOrganizer, AppConstants.roleMember],
        builder: (_) => const EventView(),
      ),
      _DashboardMenuItem(
        title: 'Sub-Event',
        subtitle: 'Kelola atau lihat sub-event per main event',
        icon: Icons.account_tree_outlined,
        requireRoles: const [
          AppConstants.roleAdmin,
          AppConstants.roleManager,
          AppConstants.roleOrganizer,
        ],
        builder: (_) => const SubEventView(),
      ),
      _DashboardMenuItem(
        title: 'Rekap Kehadiran',
        subtitle: 'Akses sesuai role (CRUD/Read)',
        icon: Icons.assignment_outlined,
        requireRoles: const [
          AppConstants.roleAdmin,
          AppConstants.roleManager,
          AppConstants.roleOrganizer,
        ],
        builder: (_) => const AttendanceRecapView(),
      ),
      _DashboardMenuItem(
        title: 'Scan Absensi',
        subtitle: 'Scanner QR untuk absensi event',
        icon: Icons.qr_code_scanner_outlined,
        requireRoles: const [AppConstants.roleAdmin, AppConstants.roleManager],
        builder: (_) => const ScanScreen(eventId: 'manual-scan'),
      ),
      _DashboardMenuItem(
        title: 'QR Pribadi',
        subtitle: 'Tampilkan QR code pribadi member',
        icon: Icons.qr_code_2,
        requireRoles: const [AppConstants.roleMember],
        builder: (_) => QrDisplayView(nim: currentUser?.memberId ?? ''),
      ),
      _DashboardMenuItem(
        title: 'Riwayat Kehadiran',
        subtitle: 'Riwayat absensi personal member',
        icon: Icons.history,
        requireRoles: const [AppConstants.roleMember],
        builder: (_) => const AttendanceHistoryView(),
      ),
      _DashboardMenuItem(
        title: 'Pengajuan Izin/Sakit',
        subtitle: 'Form izin kehadiran untuk member',
        icon: Icons.medical_information_outlined,
        requireRoles: const [AppConstants.roleMember],
        builder: (_) => const PermissionFormView(),
      ),
      _DashboardMenuItem(
        title: 'Profil Saya',
        subtitle: 'Lihat detail profil pengguna login',
        icon: Icons.account_circle_outlined,
        requireRoles: const [AppConstants.roleMember],
        builder: (_) => MemberProfileView(
          nama: currentUser?.nama ?? '-',
          nim: currentUser?.nim ?? '-',
          divisi: currentUser?.divisi ?? '-',
          memberId: currentUser?.memberId ?? '-',
        ),
      ),
    ];

    return items.where((item) => item.canAccess(role)).toList(growable: false);
  }

  Widget _buildSummaryCard(BuildContext context, String role) {
    final user = AuthController.instance.currentUser.value;
    final roleLabel = role.isEmpty ? '-' : role.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat datang, ${user?.nama ?? 'Pengguna'}'),
            const SizedBox(height: 8),
            Text('Role: $roleLabel'),
            const SizedBox(height: 4),
            Text('NIM: ${user?.nim ?? '-'}'),
            const SizedBox(height: 4),
            Text('Divisi: ${user?.divisi ?? '-'}'),
            const SizedBox(height: 12),
            Text(
              'Menu akan ditampilkan sesuai hak akses role.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _DashboardMenuItem item) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: item.builder),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = (AuthController.instance.currentUser.value?.role ??
            AppConstants.roleMember)
        .trim()
        .toLowerCase();
    final menuItems = _buildMenuItems(role);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Dashboard'),
                subtitle: Text('Role: ${role.toUpperCase()}'),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  children: menuItems.map((item) {
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      subtitle: Text(item.subtitle),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: item.builder),
                        );
                      },
                    );
                  }).toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Dashboard PRASASTI'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmAndLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(context, role),
          const SizedBox(height: 8),
          if (menuItems.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada menu yang tersedia untuk role ini.'),
              ),
            )
          else
            ...menuItems.map((item) => _buildMenuCard(context, item)),
        ],
      ),
    );
  }
}
