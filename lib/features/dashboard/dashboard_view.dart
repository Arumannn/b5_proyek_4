// ignore_for_file: unnecessary_underscores, unused_import, unused_element

import 'package:b5_proyek_4/core/constants/app_constants.dart';
import 'package:b5_proyek_4/features/attendance/attendance_history_view.dart';
import 'package:b5_proyek_4/features/member/member_profile_view.dart';
import 'package:b5_proyek_4/features/member/qr_display_view.dart';
import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../event/event_controller.dart';
import '../../core/utils/network_status_controller.dart';
import '../../core/auth/dashboard_role_policy.dart';
import 'widgets/dashboard_content.dart';
import '../../widgets/white_status_header.dart';
import '../event/event_view.dart';
import '../event/sub_event_view.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/scan_screen.dart';
import '../../models/member_model.dart';

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
  final EventController _eventController = EventController.instance;
  Future<void> _confirmAndLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Logout')),
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
        requireRoles: const [AppConstants.roleExecutive, AppConstants.roleManager],
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
        requireRoles: const [AppConstants.roleExecutive, AppConstants.roleManager],
        builder: (_, __) => const ScanScreen(eventId: 'manual-scan'),
      ),
      _DashboardMenuItem(
        title: 'Kelola Rekap Kehadiran',
        subtitle: 'Lihat, tambah, edit, hapus kehadiran + scan QR',
        icon: Icons.assignment_turned_in_outlined,
        requireRoles: const [AppConstants.roleManager],
        builder: (_, __) => const SubEventView(), // RBAC: gunakan layar event yang tersedia untuk manager.
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
        builder: (_, __) => const EventView(), // RBAC: organizer diarahkan ke event read-only yang tersedia.
      ),
      _DashboardMenuItem(
        title: 'QR Absensi Saya',
        subtitle: 'QR unik organizer + status Sudah/Belum Absen',
        icon: Icons.qr_code_2,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) => const SubEventView(), // RBAC: fallback ke modul event yang tersedia.
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
          return QrDisplayView(
            nim: currentUser.nim,
          );
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
        ),
      ),
      _DashboardMenuItem(
        title: 'Riwayat Kehadiran Saya',
        subtitle: 'Riwayat absensi personal',
        icon: Icons.history,
        requireRoles: const [AppConstants.roleMember],
        builder: (_, currentUser) => AttendanceHistoryView(
          nim: currentUser.nim,
        ),
      ),
    ];

    return items;
  }

  Widget _buildSummaryCard(BuildContext context, MemberModel currentUser) {
    final role = currentUser.role;
    final roleLabel = role.isEmpty ? '-' : role.toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${currentUser.nama}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Role: $roleLabel', style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('NIM: ${currentUser.nim}'),
            const SizedBox(height: 4),
            Text('Divisi: ${currentUser.divisi}'),
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

  Widget _buildMenuCard(BuildContext context, _DashboardMenuItem item, MemberModel currentUser) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.onTap != null) {
            item.onTap!(context, currentUser);
          } else if (item.builder != null) {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (ctx) => item.builder!(ctx, currentUser)),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
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
    return ValueListenableBuilder(
      valueListenable: AuthController.instance.currentUser,
      builder: (context, currentUser, _) {
        if (currentUser == null) {
          return Scaffold(
            appBar: const WhiteStatusHeader(
              title: 'PRASASTI',
              subtitle: 'Sistem Presensi & Administrasi Terintegrasi',
            ),
            body: const Center(child: Text('Data pengguna belum tersedia. Silakan login ulang.')),
          );
        }

        final policy = DashboardRolePolicy.forRole(currentUser.role);

        return Scaffold(
          appBar: WhiteStatusHeader(
            title: 'PRASASTI',
            subtitle: 'Sistem Presensi & Administrasi Terintegrasi',
            statusBadge: ValueListenableBuilder<bool>(
              valueListenable: NetworkStatusController.instance.isOnline,
              builder: (context, isOnline, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOnline ? const Color(0xFFE8F7EF) : const Color(0xFFFFF3E6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isOnline ? Icons.wifi : Icons.wifi_off, size: 10, color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316)),
                      const SizedBox(width: 5),
                      Text(isOnline ? 'TERSINKRONISASI' : 'OFFLINE (SIMPAN LOKAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isOnline ? const Color(0xFF15803D) : const Color(0xFFF97316))),
                    ],
                  ),
                );
              },
            ),
            actions: [
              IconButton(tooltip: 'Logout', icon: const Icon(Icons.logout, color: Color(0xFF111827)), onPressed: () => _confirmAndLogout(context)),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => await _eventController.loadEvents(force: true, cloudSync: true),
            child: DashboardContent(
              currentUser: currentUser,
              policy: policy,
              eventController: _eventController,
            ),
          ),
        );
      },
    );
  }

}
