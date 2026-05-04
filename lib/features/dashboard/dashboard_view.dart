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

  List<AttendanceRecord> _attendanceForEvent(String eventId) {
    return HiveService.attendance.values
        .where((record) => record.eventId == eventId)
        .toList(growable: false);
  }

  int _targetCount(EventModel event, int presentCount) {
    final target = event.targetPeserta.length;
    if (target > 0) return target;
    return presentCount > 0 ? presentCount : 1;
  }

  String _formatDate(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _eventStatusLabel(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggal.add(const Duration(hours: 1)));
    return isCompleted ? 'Selesai' : 'Berlangsung';
  }

  Color _eventStatusColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggal.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
  }

  Color _eventStatusBgColor(EventModel event) {
    final now = DateTime.now();
    final isCompleted = now.isAfter(event.tanggal.add(const Duration(hours: 1)));
    return isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
  }

  String _eventLocation(EventModel event) {
    final raw = event.deskripsi?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return 'Lokasi belum diatur';
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final attendance = _attendanceForEvent(event.eventId);
    final presentCount = attendance
        .where((record) => record.status.toLowerCase().contains('hadir'))
        .length;
    final targetCount = _targetCount(event, presentCount);
    final attendancePercent =
        targetCount == 0 ? 0.0 : (presentCount / targetCount).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => EventDetailView(event: event)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.nama,
                      style: const TextStyle(
                        fontSize: 34 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF283548),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _eventStatusBgColor(event),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 17,
                          color: _eventStatusColor(event),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _eventStatusLabel(event),
                          style: TextStyle(
                            color: _eventStatusColor(event),
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_formatDate(event.tanggal)} • ${_formatTime(event.jamMulai)} WIB',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _eventLocation(event),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 22, color: Color(0xFF98A2B3)),
                  const SizedBox(width: 10),
                  Text(
                    '$presentCount/$targetCount hadir',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF566377)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Kehadiran',
                    style: TextStyle(fontSize: 15, color: Color(0xFF667085)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: attendancePercent,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          attendancePercent >= 0.9
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(attendancePercent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 31 / 2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          body: ListView(
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
              const SizedBox(height: 40),
              Row(
                children: [
                  Text(
                    role == AppConstants.roleMember
                        ? 'Daftar Event'
                        : 'Event Terbaru',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${_eventController.getRootEvents().length} event',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<List<EventModel>>(
                valueListenable: _eventController.events,
                builder: (context, events, child) {
                  final rootEvents = _eventController.getRootEvents();
                  if (rootEvents.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Belum ada event. Silakan tambah data event terlebih dahulu.'),
                      ),
                    );
                  }

                  return Column(
                    children: rootEvents
                        .map((event) => _buildEventCard(context, event))
                        .toList(growable: false),
                  );
                },
              ),
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
        );
      },
    );
  }
}
