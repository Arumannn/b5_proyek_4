import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/models/event/event_model.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/domain/controllers/event/event_controller.dart';
import 'package:b5_proyek_4/presentation/widgets/dashboard/my_invitation_section.dart';
import 'package:b5_proyek_4/presentation/widgets/dashboard/member_qr_card.dart';
import 'package:b5_proyek_4/presentation/widgets/dashboard/member_today_events_section.dart';

class MemberDashboardSection extends StatelessWidget {
  final EventController eventController;
  final MemberModel currentUser;

  const MemberDashboardSection({
    super.key,
    required this.eventController,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyInvitationSection(currentNim: currentUser.nim),
        const SizedBox(height: 12),
        MemberQrCard(member: currentUser),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<EventModel>>(
          valueListenable: eventController.events,
          builder: (context, events, _) {
            final now = DateTime.now();
            final ongoing = events.where((e) => _isOngoingEvent(e, now)).toList(growable: false);

            return MemberTodayEventsSection(
              ongoingEvents: ongoing,
              member: currentUser,
            );
          },
        ),
      ],
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

