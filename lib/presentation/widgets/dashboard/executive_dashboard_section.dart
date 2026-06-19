import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:b5_proyek_4/domain/enums/status_enums.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/models/attendance/attendance_record.dart';
import 'package:b5_proyek_4/domain/models/attendance/permission_record.dart';
import 'package:b5_proyek_4/presentation/views/attendance/scan_screen.dart';
import 'package:b5_proyek_4/presentation/views/event/event_form_view.dart';
import 'package:b5_proyek_4/presentation/views/users/member_list_view.dart';
import 'package:b5_proyek_4/presentation/views/dashboard/manage_invitations_view.dart';
import 'package:b5_proyek_4/domain/controllers/event/event_controller.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/presentation/views/event/event_detail_view.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';

class ExecutiveDashboardSection extends StatefulWidget {
  const ExecutiveDashboardSection({super.key});

  @override
  State<ExecutiveDashboardSection> createState() => _ExecutiveDashboardSectionState();
}

class _ExecutiveDashboardSectionState extends State<ExecutiveDashboardSection> {
  final EventController _eventController = EventController.instance;

  @override
  void initState() {
    super.initState();
    _eventController.loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<EventModel>>(
      valueListenable: _eventController.events,
      builder: (context, events, _) {
        final now = DateTime.now();
        final rootEvents = events.where((e) => e.parentEventId == null).toList(growable: false);
        final ongoing = rootEvents.where((e) => _isOngoingEvent(e, now)).toList(growable: false)
          ..sort((a, b) => a.tanggalMulai.compareTo(b.tanggalMulai));

        return ValueListenableBuilder<Box<AttendanceRecord>>(
          valueListenable: HiveService.attendance.listenable(),
          builder: (context, attendanceBox, _) {
            final totalHadir = attendanceBox.values.length;

            return ValueListenableBuilder<Box<PermissionRecord>>(
              valueListenable: HiveService.permissions.listenable(),
              builder: (context, permissionsBox, _) {
                final izinSakit = permissionsBox.values
                    .where((p) => p.statusEnum == PermissionStatus.approved)
                    .length;
                final perluValidasi = permissionsBox.values
                    .where((p) => p.statusEnum == PermissionStatus.pending)
                    .length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top stats area: big left card + two small right cards
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 14,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Total Hadir', style: TextStyle(color: Color(0xFFDFF6F0), fontSize: 12, fontWeight: FontWeight.w600)),
                                        Icon(Icons.bar_chart, color: const Color(0xFFDBEAFE)),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text('$totalHadir', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _smallStatCard('Izin / Sakit', '$izinSakit', Icons.description, const Color(0xFFFFEDD5), const Color(0xFFF97316)),
                                const SizedBox(height: 12),
                                _smallStatCard('Perlu Validasi', '$perluValidasi', Icons.check_circle, const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'MENU ADMINISTRASI',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                      children: [
                        _menuAction(context, 'Buat Event', Icons.calendar_today, const Color(0xFF2563EB), const Color(0xFFDBEAFE), () async {
                          final isManager = (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase() == AppConstants.roleManager;
                          final parentOptions = _eventController.getRootEvents()
                              .map((e) => EventParentOption(id: e.eventId, name: e.nama))
                              .toList();
                          final result = await Navigator.push<EventFormValue>(
                            context, 
                            MaterialPageRoute(
                              builder: (_) => EventFormView(
                                title: isManager ? 'Buat Sub-Event' : 'Buat Event Baru',
                                parentOptions: parentOptions,
                              ),
                            ),
                          );
                          if (result == null) return;
                          final success = await _eventController.createEvent(
                            nama: result.name,
                            tanggalMulai: result.date,
                            tanggalSelesai: result.endDate,
                            jamSelesai: result.jamSelesai,
                            parentEventId: result.isSubEvent ? result.parentId : null,
                            jenis: result.jenis,
                            lokasi: result.lokasi,
                            deskripsi: result.deskripsi,
                            targetPeserta: result.targetPeserta,
                            requiresInvitation: result.requiresInvitation,
                            penyelenggara: result.penyelenggara,
                            penanggungJawab: result.penanggungJawab,
                          );
                          if (!mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event berhasil ditambahkan.')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_eventController.errorMessage.value ?? 'Gagal menambah event.')));
                          }
                        }),
                        _menuAction(context, 'Undangan', Icons.mail, const Color(0xFFF59E0B), const Color(0xFFFFF7ED), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageInvitationsView()));
                        }),
                        _menuAction(context, 'Anggota', Icons.people, const Color(0xFF7C3AED), const Color(0xFFEDE9FE), () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberListView()));
                        }),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Event Berlangsung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    const SizedBox(height: 12),
                    if (ongoing.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'Belum ada event yang tampil saat ini.',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                        ),
                      )
                    else
                      Column(
                        children: ongoing.map((e) => _ongoingEventCard(context, e, highlight: true)).toList(),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  bool _isOngoingEvent(EventModel event, DateTime now) {
    final status = event.statusEvent.toLowerCase();
    if (status.contains('berlangsung') || status.contains('berjalan')) {
      return true;
    }

    final eventDay = DateTime(event.tanggalMulai.year, event.tanggalMulai.month, event.tanggalMulai.day);
    final today = DateTime(now.year, now.month, now.day);
    if (eventDay != today) {
      return false;
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


  Widget _smallStatCard(String label, String value, IconData icon, Color bg, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: accent, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _menuAction(BuildContext context, String title, IconData icon, Color accent, Color tint, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(999)), child: Icon(icon, color: accent)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ],
        ),
      ),
    );
  }

  Widget _ongoingEventCard(BuildContext context, EventModel event, {bool highlight = false}) {
    final startTime = event.jamMulai ?? event.tanggalMulai;
    return GestureDetector(
      onTap: () {
        final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => EventDetailView(
              event: event,
              userRole: role,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(event.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: highlight ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  highlight ? 'Berlangsung' : event.statusEvent,
                  style: TextStyle(
                    color: highlight ? const Color(0xFF16A34A) : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.penanggungJawab?.trim().isNotEmpty == true
                ? 'PJ: ${event.penanggungJawab}'
                : 'PJ belum diatur',
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text('${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year} • ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} WIB', style: const TextStyle(color: Color(0xFF566377), fontSize: 13)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ScanScreen(eventId: event.eventId)),
                );
              },
              icon: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
              label: const Text('Buka Scanner', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(backgroundColor: const Color(0xFFDBEAFE), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ],
      ),
    ));
  }
}
