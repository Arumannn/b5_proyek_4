import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../../models/member_model.dart';
import '../../attendance/attendance_history_view.dart';
import '../../event/event_view.dart';

/// Menampilkan daftar kegiatan berlangsung hari ini dan tombol riwayat.
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
          children: [
            const Expanded(
              child: Text(
                'Kegiatan Hari Ini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EventView())),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Lihat Semua',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (ongoingEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Belum ada kegiatan hari ini')),
          )
        else
          Column(
            children: ongoingEvents.map((event) {
              return _EventCard(event: event);
            }).toList(),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: member.nim.trim().isEmpty
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AttendanceHistoryView(nim: member.nim),
                    ),
                  ),
          icon: const Icon(Icons.history),
          label: const Text('Lihat Riwayat Saya'),
        ),
      ],
    );
  }
}

/// Widget individual untuk satu kartu kegiatan.
class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${event.jamMulai != null ? '${event.jamMulai!.hour.toString().padLeft(2, '0')}:${event.jamMulai!.minute.toString().padLeft(2, '0')}' : '--:--'} • ${event.lokasi ?? 'Lokasi belum diatur'}',
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
                      child: const Text(
                        'Ajukan Izin/Sakit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
