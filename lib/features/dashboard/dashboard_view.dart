import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../event/event_controller.dart';
import '../../core/utils/network_status_controller.dart';
import 'widgets/executive_dashboard_section.dart';
import '../../widgets/white_status_header.dart';
import 'dashboard_permission.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final EventController _eventController = EventController.instance;

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
        final showExecutiveAdmin = DashboardPermission.showExecutiveAdmin(role);

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
          ),
          body: RefreshIndicator(
            onRefresh: () async => _eventController.refreshEvents(cloudSync: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (showExecutiveAdmin) ...[
                  const ExecutiveDashboardSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
