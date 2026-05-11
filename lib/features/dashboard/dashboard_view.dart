import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../models/attendance_record.dart';
import '../../models/event_model.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/stats_grid.dart';
import '../../widgets/quick_actions.dart';
import '../attendance/attendance_history_view.dart';
import '../attendance/scan_screen.dart';
import '../auth/auth_controller.dart';
import '../event/event_controller.dart';
import '../event/event_detail_view.dart';
import '../../widgets/event_list_section.dart';
import '../laporan/laporan_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final EventController _eventController = EventController.instance;

  @override
  void initState() {
    super.initState();
    _eventController.loadEvents();
  }

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: AuthController.instance.currentUser,
      builder: (context, currentUser, _) {
        if (currentUser == null) {
          return Scaffold(
            appBar: const GradientHeader(title: 'Dashboard PRASASTI'),
            body: const Center(
              child: Text('Data pengguna belum tersedia. Silakan login ulang.'),
            ),
          );
        }

        final role = currentUser.role.trim().toLowerCase();

        return Scaffold(
          appBar: GradientHeader(
            title: 'Dashboard PRASASTI',
            actions: [
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () => _confirmAndLogout(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _eventController.loadEvents(force: true, cloudSync: true);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
            children: [
              // Stats grid (2x2)
              StatsGrid(
                items: [
                  StatItem(icon: Icons.group, label: 'Total Anggota', value: '156', bgColor: const Color(0xFF60A5FA)),
                  StatItem(icon: Icons.check_circle, label: 'Kehadiran', value: '87%', bgColor: const Color(0xFF22C55E)),
                  StatItem(icon: Icons.event, label: 'Rapat', value: '8', bgColor: const Color(0xFF9333EA)),
                  StatItem(icon: Icons.trending_up, label: 'Partisipasi', value: '92%', bgColor: const Color(0xFFF97316)),
                ],
              ),
              const SizedBox(height: 16),
              // Quick actions
              QuickActions(
                onFillAttendance: () {
                  // Get latest event if available
                  final eventsList = _eventController.events.value;
                  final latestEvent = eventsList.isNotEmpty ? eventsList.first : null;
                  if (latestEvent != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ScanScreen(eventId: latestEvent.eventId)));
                  }
                },
                onReports: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanView()));
                },
              ),
              const SizedBox(height: 16),
              const EventListSection(),
              if (role == AppConstants.roleMember) ...[
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => AttendanceHistoryView(
                          nim: currentUser.nim,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Lihat Riwayat Saya'),
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