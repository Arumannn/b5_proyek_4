import 'package:flutter/material.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/presentation/views/event/event_view.dart';
import 'package:b5_proyek_4/presentation/views/event/event_detail_view.dart';
import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/presentation/views/attendance/permission_form_view.dart';

class MemberTodayEventsSection extends StatelessWidget {
  final List<EventModel> ongoingEvents;
  final MemberModel member;

  const MemberTodayEventsSection({
    super.key,
    required this.ongoingEvents,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Event Hari Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventView())),
              child: const Text('Lihat Semua', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (ongoingEvents.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: const Text('Belum ada event yang berlangsung hari ini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
          )
        else
          Column(
            children: ongoingEvents.map((event) => _EventCard(event: event)).toList(),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  String _formatTime(DateTime? time) {
    if (time == null) return '00:00';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMainEvent = event.parentEventId == null;
    final String typeLabel = isMainEvent ? 'Event Utama' : 'Sub-Event';
    final startTime = event.jamMulai ?? event.tanggalMulai;
    final timeStr = _formatTime(startTime);
    final dateStr = '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}';
    final locationStr = event.lokasi ?? event.jenis;

    return GestureDetector(
      onTap: () {
        final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                        child: Text(typeLabel.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), letterSpacing: 0.5)),
                      ),
                      const SizedBox(height: 8),
                      Text(event.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('$dateStr • $timeStr WIB', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(locationStr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12))), 
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PermissionFormView(
                            eventId: event.eventId, 
                            eventTitle: event.nama,
                            onSuccessSubmit: () {
                              // Di sini bisa ditambahkan logika tambahan jika butuh
                            }
                          ))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFF7ED),
                            foregroundColor: const Color(0xFFEA580C),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFFFEDD5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Ajukan Izin/Sakit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}