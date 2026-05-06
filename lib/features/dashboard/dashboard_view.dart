import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/design_system.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../../widgets/network_status_banner.dart';
import '../attendance/attendance_history_view.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../event/event_view.dart';
import '../event/sub_event_view.dart';
import '../member/member_profile_view.dart';
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
    this.builder,
    this.onTap,
    this.requireRoles = const <String>[],
  }) : assert(builder != null || onTap != null);

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext context, MemberModel currentUser)? builder;
  final void Function(BuildContext context, MemberModel currentUser)? onTap;
  final List<String> requireRoles;

  bool canAccess(String role) {
    if (requireRoles.isEmpty) return true;
    // RBAC: role check dibuat case-insensitive agar konsisten dengan source role campuran.
    final normalizedRole = role.trim().toLowerCase();
    return requireRoles.any(
      (allowed) => allowed.trim().toLowerCase() == normalizedRole,
    );
  }
}

class _DashboardViewState extends State<DashboardView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  List<_DashboardMenuItem> _buildMenuItems() {
    final items = <_DashboardMenuItem>[
      _DashboardMenuItem(
        title: 'Kelola Pengguna',
        subtitle: 'CRUD akun pengguna',
        icon: Icons.groups_2_outlined,
        requireRoles: const [AppConstants.roleExecutive],
        builder: (_, __) => const UserManagementView(),
      ),
      _DashboardMenuItem(
        title: 'Kelola Event & Sub-Event',
        subtitle: 'CRUD main event + sub-event (sesuai role)',
        icon: Icons.event_note_outlined,
        requireRoles: const [
          AppConstants.roleExecutive,
          AppConstants.roleManager,
        ],
        builder: (_, __) => const EventView(),
      ),
      _DashboardMenuItem(
        title: 'Manajemen Anggota',
        subtitle: 'CRUD akun Admin, Manager, Organizer, dan Member',
        icon: Icons.groups_2_outlined,
        requireRoles: const [AppConstants.roleExecutive],
        builder: (_, __) => const UserManagementView(),
      ),
      _DashboardMenuItem(
        title: 'Lihat Event & Sub-Event',
        subtitle: 'Akses read-only daftar event',
        icon: Icons.visibility_outlined,
        requireRoles: const [AppConstants.roleMember],
        builder: (_, __) => const EventView(),
      ),
      _DashboardMenuItem(
        title: 'Sub-Event',
        subtitle: 'Kelola atau lihat sub-event per main event',
        icon: Icons.account_tree_outlined,
        requireRoles: const [
          AppConstants.roleExecutive,
          AppConstants.roleManager,
          AppConstants.roleOrganizer,
        ],
        builder: (_, __) => const SubEventView(),
      ),
      _DashboardMenuItem(
        title: 'Rekap Kehadiran',
        subtitle: 'Lihat ringkasan kehadiran per event',
        icon: Icons.assignment_outlined,
        requireRoles: const [
          AppConstants.roleExecutive,
          AppConstants.roleManager,
          AppConstants.roleOrganizer,
        ],
        builder: (_, __) => const AttendanceRecapView(),
      ),
      _DashboardMenuItem(
        title: 'Scan Absensi',
        subtitle: 'Scanner QR untuk absensi event',
        icon: Icons.qr_code_scanner_outlined,
        requireRoles: const [
          AppConstants.roleExecutive,
          AppConstants.roleManager,
        ],
        builder: (_, __) => const ScanScreen(eventId: 'manual-scan'),
      ),
      _DashboardMenuItem(
        title: 'Kelola Rekap Kehadiran',
        subtitle: 'Lihat, tambah, edit, hapus kehadiran + scan QR',
        icon: Icons.assignment_turned_in_outlined,
        requireRoles: const [AppConstants.roleManager],
        builder: (_, __) =>
            const SubEventView(), // RBAC: gunakan layar event yang tersedia untuk manager.
      ),

      // ==========================================
      // ORGANIZER MENUS
      // ==========================================
      _DashboardMenuItem(
        title: 'Lihat Event Utama & Sub-Event (Organizer)',
        subtitle: 'Read-only daftar event dan detail tanpa CRUD',
        icon: Icons.event_note_outlined,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) => const EventView(),
      ),
      _DashboardMenuItem(
        title: 'Rekap Kehadiran',
        subtitle: 'Tabel NIM, Nama, Status Kehadiran, Timestamp',
        icon: Icons.assignment_outlined,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) =>
            const EventView(), // RBAC: organizer diarahkan ke event read-only yang tersedia.
      ),
      _DashboardMenuItem(
        title: 'QR Absensi Saya',
        subtitle: 'QR unik organizer + status Sudah/Belum Absen',
        icon: Icons.qr_code_2,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) =>
            const SubEventView(), // RBAC: fallback ke modul event yang tersedia.
      ),

      // ==========================================
      // MEMBER MENUS
      // ==========================================
      _DashboardMenuItem(
        title: 'QR Code Saya',
        subtitle: 'Gunakan QR ini saat absensi',
        icon: Icons.qr_code_2,
        requireRoles: const [AppConstants.roleMember],
        builder: (_, currentUser) {
          return QrDisplayView(nim: currentUser.nim);
        },
      ),
      _DashboardMenuItem(
        title: 'Profil Saya',
        subtitle: 'Lihat detail profil pengguna login',
        icon: Icons.account_circle,
        requireRoles: const [AppConstants.roleMember],
        builder: (_, currentUser) => MemberProfileView(
          nama: currentUser.nama,
          nim: currentUser.nim,
          divisi: currentUser.divisi,
          memberId: currentUser.memberId,
        ),
      ),
      _DashboardMenuItem(
        title: 'Riwayat Kehadiran Saya',
        subtitle: 'Riwayat absensi personal',
        icon: Icons.history,
        requireRoles: const [AppConstants.roleMember],
        builder: (_, currentUser) => AttendanceHistoryView(
          memberId: currentUser.memberId,
          nim: currentUser.nim,
        ),
      ),
    ];

    return items;
  }

  String _formatShortDate(DateTime value) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${value.day.toString().padLeft(2, '0')} ${monthNames[value.month - 1]} ${value.year}';
  }

  Color _eventColor(String jenis) {
    switch (jenis.trim().toLowerCase()) {
      case 'rapat':
        return const Color(0xFF3B82F6);
      case 'acara':
        return const Color(0xFFB84DFF);
      case 'kegiatan':
        return const Color(0xFF06C755);
      default:
        return const Color(0xFFFF7A00);
    }
  }

  void _openMenuItem(_DashboardMenuItem item, MemberModel currentUser) {
    if (item.onTap != null) {
      item.onTap!(context, currentUser);
      return;
    }
    if (item.builder != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (ctx) => item.builder!(ctx, currentUser),
        ),
      );
    }
  }

  void _openMenuByTitle(String title, MemberModel currentUser) {
    for (final item in _buildMenuItems()) {
      if (item.title == title) {
        _openMenuItem(item, currentUser);
        return;
      }
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.displaySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  Widget _buildActivityCard(EventModel event, {required bool isUpcoming}) {
    final accent = _eventColor(event.jenis);
    return Card(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.nama,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                Icon(
                  isUpcoming ? Icons.chevron_right : Icons.check_circle_outline,
                  color: AppColors.textOnPrimary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_formatShortDate(event.tanggal)}${event.jamMulai != null ? ' • ${TimeOfDay.fromDateTime(event.jamMulai!).format(context)}' : ''}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.parentEventId == null
                            ? 'Rapat / Kegiatan HIMAKOM'
                            : 'Sub-event',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const EventView(),
                      ),
                    ),
                    child: const Text('Lihat Detail & Daftar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(
    MemberModel currentUser,
    List<_DashboardMenuItem> menuItems,
  ) {
    final initials = currentUser.nama.isNotEmpty
        ? currentUser.nama[0].toUpperCase()
        : 'A';
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
              child: Row(
                children: [
                  Text(
                    'Menu',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...menuItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: item.title == 'Dashboard'
                            ? AppColors.primarySurface
                            : null,
                        leading: Icon(
                          item.icon,
                          color: item.title == 'Dashboard'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openMenuItem(item, currentUser);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.nama,
                            style: AppTypography.titleMedium,
                          ),
                          Text(
                            currentUser.divisi,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _confirmAndLogout(context);
                      },
                      icon: const Icon(Icons.logout, color: AppColors.error),
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthController.instance.currentUser,
      builder: (context, currentUser, _) {
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dashboard PRASASTI')),
            body: const Center(
              child: Text('Data pengguna belum tersedia. Silakan login ulang.'),
            ),
          );
        }

        final role = currentUser.role.trim().toLowerCase();
        final menuItems = _buildMenuItems()
            .where((item) => item.canAccess(role))
            .toList();

        final members = HiveService.members.values.toList(growable: false);
        final events = HiveService.events.values.toList(growable: false)
          ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
        final attendances = HiveService.attendance.values.toList(
          growable: false,
        );

        final totalMembers = members.length;
        final totalMeetings = events
            .where((event) => event.jenis.trim().toLowerCase() == 'rapat')
            .length;
        final attendanceRate = attendances.isEmpty
            ? 0
            : ((attendances
                              .where(
                                (r) => r.status.trim().toLowerCase() == 'hadir',
                              )
                              .length /
                          attendances.length) *
                      100)
                  .round();

        final recentEvents = events.reversed.take(3).toList(growable: false);
        final upcomingEvents = events
            .where((event) => !event.tanggal.isBefore(DateTime.now()))
            .take(3)
            .toList(growable: false);

        return NetworkStatusBanner(
          child: Scaffold(
            key: _scaffoldKey,
            drawer: _buildDrawer(currentUser, menuItems),
            appBar: AppBar(
              toolbarHeight: 96,
              centerTitle: false,
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIMAKOM',
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Dashboard Absensi',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              leading: IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Notifikasi',
                      icon: const Icon(Icons.notifications_none_outlined),
                      onPressed: () {},
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      currentUser.nama.isNotEmpty
                          ? currentUser.nama[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatCard(
                      icon: Icons.groups_2_outlined,
                      iconColor: const Color(0xFF3B82F6),
                      value: '$totalMembers',
                      label: 'Total Anggota',
                    ),
                    _buildStatCard(
                      icon: Icons.verified_user_outlined,
                      iconColor: const Color(0xFF06C755),
                      value: '$attendanceRate%',
                      label: 'Kehadiran',
                    ),
                    _buildStatCard(
                      icon: Icons.event_outlined,
                      iconColor: const Color(0xFFB84DFF),
                      value: '$totalMeetings',
                      label: 'Rapat',
                    ),
                    _buildStatCard(
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFFFF7A00),
                      value:
                          '${((totalMembers == 0 ? 0 : (attendanceRate / 100) * totalMembers)).round()}%',
                      label: 'Partisipasi',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aksi Cepat',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                context,
                                label: 'Isi Absensi',
                                icon: Icons.add,
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                                onTap: () => _openMenuByTitle(
                                  'Scan Absensi',
                                  currentUser,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                context,
                                label: 'Laporan',
                                icon: Icons.description_outlined,
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.textPrimary,
                                onTap: () => _openMenuByTitle(
                                  'Rekap Kehadiran',
                                  currentUser,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Kegiatan Terakhir',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Mendatang',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...[...recentEvents, ...upcomingEvents]
                    .take(3)
                    .map(
                      (event) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildActivityCard(
                          event,
                          isUpcoming: !event.tanggal.isBefore(DateTime.now()),
                        ),
                      ),
                    ),
                if (menuItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Menu Terkait',
                    style: AppTypography.headlineSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(
                    menuItems.length.clamp(0, 3),
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: index < 2 ? 10 : 0),
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primarySurface,
                            child: Icon(
                              menuItems[index].icon,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(menuItems[index].title),
                          subtitle: Text(menuItems[index].subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _openMenuItem(menuItems[index], currentUser),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
