import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/design_system.dart';
import '../../core/services/hive_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../attendance/attendance_history_view.dart';
import '../auth/auth_controller.dart';
import '../auth/user_management_view.dart';
import '../event/event_controller.dart';
import '../event/event_view.dart';
import '../../core/utils/network_status_controller.dart';
import 'widgets/executive_dashboard_section.dart';
import '../../widgets/white_status_header.dart';
import '../../models/event_model.dart';

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

        final role = currentUser.role.trim().toLowerCase();
        final isManager = role == AppConstants.roleExecutive.toLowerCase() || role == AppConstants.roleManager.toLowerCase();

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
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (isManager) ...[
                  const ExecutiveDashboardSection(),
                ] else ...[
                  // Member: invitation banner
                  ValueListenableBuilder(
                    valueListenable: HiveService.invitations.listenable(),
                    builder: (context, Box box, _) {
                      final hasPending = box.values.where((inv) => inv.nim == currentUser.nim && (inv.responseStatus == '' || inv.responseStatus == 'pending')).isNotEmpty;
                      if (!hasPending) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]), borderRadius: BorderRadius.circular(20)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Text('Undangan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                            const SizedBox(height: 8),
                            const Text('Musyawarah Besar (MUBES)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('20 Mei 2026 • 08:00 WIB', style: TextStyle(color: Color(0xFFFFEFD5), fontSize: 12)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFFF97316),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              onPressed: () {},
                              child: const Text('Lihat & Konfirmasi', maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ])),
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 64,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Opacity(opacity: 0.12, child: Icon(Icons.mail, size: 64, color: Colors.white)),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // QR Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      const Text('QR Code Kehadiran Anda', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                      const SizedBox(height: 12),
                      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: const Icon(Icons.qr_code, size: 120, color: Color(0xFF111827))),
                      const SizedBox(height: 10),
                        Text(currentUser.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      const SizedBox(height: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(999)), child: Text('NIM: ${currentUser.nim}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600))),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // Kegiatan Hari Ini (ongoing events)
                  ValueListenableBuilder<List<EventModel>>(
                    valueListenable: _eventController.events,
                    builder: (context, events, _) {
                      final now = DateTime.now();
                      final ongoing = events.where((e) => _isOngoingEvent(e, now)).toList(growable: false);

                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Expanded(child: Text('Kegiatan Hari Ini', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)))),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventView())),
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('Lihat Semua', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF2563EB))),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        if (ongoing.isEmpty) ...[
                          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: const Center(child: Text('Belum ada kegiatan hari ini'))),
                        ] else ...[
                          Column(children: ongoing.map((e) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
                              child: Row(children: [
                                Container(width: 6, height: 90, decoration: const BoxDecoration(color: Color(0xFF2563EB), borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
                                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(e.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${e.jamMulai != null ? '${e.jamMulai!.hour.toString().padLeft(2, '0')}:${e.jamMulai!.minute.toString().padLeft(2, '0')}' : '--:--'} • ${e.lokasi ?? 'Lokasi belum diatur'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFF7ED),
                                        foregroundColor: const Color(0xFFF97316),
                                        minimumSize: const Size(0, 34),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: const Text('Ajukan Izin/Sakit', maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                ]))),
                              ]),
                            );
                          }).toList())
                        ]
                      ]);
                    },
                  ),

                  const SizedBox(height: 12),
                  OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => AttendanceHistoryView(nim: currentUser.nim))), icon: const Icon(Icons.history), label: const Text('Lihat Riwayat Saya')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isOngoingEvent(EventModel event, DateTime now) {
    final status = event.statusEvent.toLowerCase();
    if (status.contains('berlangsung') || status.contains('berjalan')) {
      return true;
    }

    final startTime = event.jamMulai ?? event.tanggalMulai;
    final endTime = event.jamSelesai ?? event.tanggalSelesai ?? DateTime(
      event.tanggalMulai.year,
      event.tanggalMulai.month,
      event.tanggalMulai.day,
      23,
      59,
      59,
    );
    return !now.isBefore(startTime) && !now.isAfter(endTime);
  }
}
