import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/utils/qr_service.dart';
import '../../models/event_model.dart';
import '../../models/member_model.dart';
import '../attendance/attendance_history_view.dart';
import '../attendance/attendance_recap_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../event/event_list_view.dart';
import '../manager/manager_attendance_management_view.dart';
import '../manager/manager_sub_event_management_view.dart';
import '../manager/manager_user_readonly_view.dart';
import '../member/member_profile_view.dart';
import '../member/qr_display_view.dart';
import '../organizer/organizer_attendance_recap_view.dart';
import '../organizer/organizer_event_overview_view.dart';
import '../organizer/organizer_qr_view.dart';

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

  Future<void> _openScanForSelectedEvent(BuildContext context) async {
    final allEvents = HiveService.events.values.toList();
    final events = allEvents.where((e) {
      bool isMain = e.parentEventId == null;
      bool hasSub = allEvents.any((sub) => sub.parentEventId == e.eventId);
      return !(isMain && hasSub);
    }).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));

    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada event. Silakan buat event terlebih dahulu.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<EventModel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Pilih Event untuk Scan'),
                subtitle: Text('QR anggota akan dicatat ke event ini.'),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    final event = events[index];
                    return ListTile(
                      title: Text(event.nama),
                      subtitle: Text(
                        '${event.jenis} • ${event.tanggal.toLocal()}',
                      ),
                      onTap: () => Navigator.of(sheetContext).pop(event),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(eventId: selected.eventId),
      ),
    );
  }

  List<_DashboardMenuItem> _buildMenuItems() {
    return [
      // ==========================================
      // ADMIN MENUS
      // ==========================================
      _DashboardMenuItem(
        title: 'Kelola Event',
        subtitle: 'Tambah, edit, hapus event dan sub event',
        icon: Icons.event_note_outlined,
        requireRoles: const [AppConstants.roleAdmin],
        builder: (_, __) => const EventListView(),
      ),
      _DashboardMenuItem(
        title: 'Manajemen Anggota',
        subtitle: 'CRUD akun Admin, Manager, Organizer, dan Member',
        icon: Icons.groups_2_outlined,
        requireRoles: const [AppConstants.roleAdmin],
        builder: (_, __) => const UserManagementView(),
      ),
      _DashboardMenuItem(
        title: 'Scan Absensi',
        subtitle: 'Pilih event lalu scan QR anggota',
        icon: Icons.qr_code_scanner_outlined,
        requireRoles: const [AppConstants.roleAdmin],
        onTap: (ctx, _) => _openScanForSelectedEvent(ctx),
      ),
      _DashboardMenuItem(
        title: 'Rekap Kehadiran',
        subtitle: 'Lihat ringkasan kehadiran per event',
        icon: Icons.assignment_outlined,
        requireRoles: const [AppConstants.roleAdmin],
        builder: (_, __) => const AttendanceRecapView(),
      ),

      // ==========================================
      // MANAGER MENUS
      // ==========================================
      _DashboardMenuItem(
        title: 'Data Akun Pengguna',
        subtitle: 'Read-only NIM, Nama, Role, dan DBU',
        icon: Icons.people_outline,
        requireRoles: const [AppConstants.roleManager],
        builder: (_, __) => const ManagerUserReadonlyView(),
      ),
      _DashboardMenuItem(
        title: 'Kelola Sub-Event',
        subtitle: 'Full CRUD sub-event dengan relasi event utama',
        icon: Icons.account_tree_outlined,
        requireRoles: const [AppConstants.roleManager],
        builder: (_, __) => const ManagerSubEventManagementView(),
      ),
      _DashboardMenuItem(
        title: 'Kelola Rekap Kehadiran',
        subtitle: 'Lihat, tambah, edit, hapus kehadiran + scan QR',
        icon: Icons.assignment_turned_in_outlined,
        requireRoles: const [AppConstants.roleManager],
        builder: (_, __) => const ManagerAttendanceManagementView(),
      ),

      // ==========================================
      // ORGANIZER MENUS
      // ==========================================
      _DashboardMenuItem(
        title: 'Lihat Event Utama & Sub-Event',
        subtitle: 'Read-only daftar event dan detail tanpa CRUD',
        icon: Icons.event_note_outlined,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) => const OrganizerEventOverviewView(),
      ),
      _DashboardMenuItem(
        title: 'Rekap Kehadiran',
        subtitle: 'Tabel NIM, Nama, Status Kehadiran, Timestamp',
        icon: Icons.assignment_outlined,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) => const OrganizerAttendanceRecapView(),
      ),
      _DashboardMenuItem(
        title: 'QR Absensi Saya',
        subtitle: 'QR unik organizer + status Sudah/Belum Absen',
        icon: Icons.qr_code_2,
        requireRoles: const [AppConstants.roleOrganizer],
        builder: (_, __) => const OrganizerQrView(),
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
          final qrData = currentUser.qrCodeValue.isNotEmpty
              ? currentUser.qrCodeValue
              : QrService.generateQrData(currentUser.nim);
          return QrDisplayView(
            nim: currentUser.nim,
            qrData: qrData,
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
            appBar: AppBar(title: const Text('Dashboard PRASASTI')),
            body: const Center(
              child: Text('Data pengguna belum tersedia. Silakan login ulang.'),
            ),
          );
        }

        final role = currentUser.role.trim().toLowerCase();
        final menuItems = _buildMenuItems().where((item) => item.canAccess(role)).toList();

        return Scaffold(
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
              _buildSummaryCard(context, currentUser),
              const SizedBox(height: 8),
              if (menuItems.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Tidak ada menu yang tersedia untuk role ini.'),
                  ),
                )
              else
                ...menuItems.map((item) => _buildMenuCard(context, item, currentUser)),
            ],
          ),
        );
      },
    );
  }
}
