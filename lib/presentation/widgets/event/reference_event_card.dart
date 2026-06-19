import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/presentation/views/event/event_detail_view.dart';
import 'package:b5_proyek_4/presentation/widgets/event/event_utilities.dart';

class ReferenceEventCard extends StatelessWidget {
  final EventModel event;

  const ReferenceEventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final accent = EventUtilities.eventAccentColor(event);
    final tint = EventUtilities.eventTintColor(event);
    final status = EventUtilities.eventStatusTitle(event);
    final dateText = EventUtilities.formatDate(event.tanggalMulai);
    final startTime = event.jamMulai ?? event.tanggalMulai;
    final timeText = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final location = EventUtilities.eventLocation(event);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
          );
        },
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: tint,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                event.jenis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              event.nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildEventMetaRow(Icons.schedule_outlined, '$timeText WIB', const Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  _buildEventMetaRow(Icons.location_on_outlined, location, const Color(0xFF6B7280)),
                  const SizedBox(height: 8),
                  _buildEventMetaRow(Icons.groups_outlined, '${EventUtilities.targetCount(event, 0)} target peserta', const Color(0xFF6B7280)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final role = AuthController.instance.currentUser.value?.role ?? AppConstants.roleMember;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventDetailView(event: event, userRole: role)),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventMetaRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ),
      ],
    );
  }
}
