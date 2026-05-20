import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../attendance/attendance_history_view.dart';
import '../auth/auth_controller.dart';
import '../event/event_controller.dart';
import '../event/event_view.dart';
import '../../core/utils/network_status_controller.dart';
import 'widgets/my_invitation_section.dart';
import 'widgets/executive_dashboard_section.dart';
import '../../widgets/white_status_header.dart';
import '../../models/event_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
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
                  MyInvitationSection(currentNim: currentUser.nim),

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
