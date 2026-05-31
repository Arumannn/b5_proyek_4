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
import '../member/qr_display_view.dart';
import '../../widgets/custom_confirm_dialog.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/qr_service.dart';

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
        return const CustomConfirmDialog(
          title: 'Logout',
          content: 'Yakin ingin keluar dari akun ini?',
          confirmText: 'Logout',
          isDestructive: true,
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
            onRefresh: () async => _eventController.refreshEvents(cloudSync: true),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'QR Code Kehadiran Anda',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => QrDisplayView(nim: currentUser.nim)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 0)),
                              ],
                              border: Border.all(color: Colors.grey.shade200, width: 2), // We will just use solid border if dotted is not available, wait let's just use normal border to be safe
                            ),
                            child: QrImageView(
                              data: QrService.generateQrData(currentUser.nim),
                              version: QrVersions.auto,
                              size: 160,
                              gapless: false,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUser.nama,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'NIM: ${currentUser.nim}',
                            style: TextStyle(color: Colors.blue.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Event Hari Ini (ongoing events)
                  ValueListenableBuilder<List<EventModel>>(
                    valueListenable: _eventController.events,
                    builder: (context, events, _) {
                      final now = DateTime.now();
                      final ongoing = events.where((e) => _isOngoingEvent(e, now) && e.parentEventId == null).toList(growable: false);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Event Hari Ini',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventView())),
                                child: Text(
                                  'Lihat Semua',
                                  style: TextStyle(color: Colors.blue.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (ongoing.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                              child: const Center(child: Text('Belum ada event hari ini', style: TextStyle(color: Colors.grey))),
                            ),
                          ] else ...[
                            Column(
                              children: ongoing.map((e) {
                                final startTime = e.jamMulai ?? e.tanggalMulai;
                                final timeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} WIB';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(width: 4, color: Colors.blue.shade500),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                e.parentEventId == null ? 'EVENT UTAMA' : 'SUB-EVENT',
                                                style: TextStyle(color: Colors.blue.shade600, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              e.nama,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(timeStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                                const SizedBox(width: 12),
                                                Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(e.lokasi ?? 'Lokasi belum diatur', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            const Divider(height: 1, color: Color(0xFFF9FAFB)),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () {},
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange.shade50,
                                                  foregroundColor: Colors.orange.shade600,
                                                  elevation: 0,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                    side: BorderSide(color: Colors.orange.shade100),
                                                  ),
                                                ),
                                                child: const Text('Ajukan Izin/Sakit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          ],
                        ],
                      );
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
