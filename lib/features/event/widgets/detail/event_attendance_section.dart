import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../models/event_model.dart';
import '../../../../models/event_invitation.dart';
import '../../../../widgets/status_badge.dart';
import '../../../../core/enums/status_enums.dart';
import '../../../../widgets/user_avatar.dart';
import '../../../member/invitation_response_page.dart';

class AttendanceParticipantItem {
  final String nim;
  final String displayName;
  final String role;
  final String status;
  final DateTime? time;

  const AttendanceParticipantItem({
    required this.nim,
    required this.displayName,
    required this.role,
    required this.status,
    required this.time,
  });
}

class EventAttendanceSection extends StatelessWidget {
  final EventModel currentEvent;
  final bool canManageInvitationResponses;
  final List<AttendanceParticipantItem> attendanceList;

  const EventAttendanceSection({
    super.key,
    required this.currentEvent,
    required this.canManageInvitationResponses,
    required this.attendanceList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentEvent.requiresInvitation && (canManageInvitationResponses || HiveService.invitations.values.any((inv) => inv.eventId == currentEvent.eventId))) ...[
          ValueListenableBuilder<Box<EventInvitation>>(
            valueListenable: HiveService.invitations.listenable(),
            builder: (context, box, _) {
              final invitations = box.values
                  .where((inv) => inv.eventId == currentEvent.eventId)
                  .toList(growable: false);

              final approved = invitations.where((inv) {
                final status = inv.responseStatusEnum;
                return status == InvitationStatus.approved || status == InvitationStatus.autoApproved;
              }).length;
              final rejected = invitations.where((inv) => inv.responseStatusEnum == InvitationStatus.rejected).length;
              final pending = invitations.where((inv) => inv.responseStatusEnum == InvitationStatus.pending).length;
              final permission = invitations.where((inv) => inv.responseStatusEnum == InvitationStatus.permissionRequested).length;
              final total = invitations.length;

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withValues(alpha: 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned(
                      right: -6,
                      top: -10,
                      child: Opacity(
                        opacity: 0.18,
                        child: Icon(Icons.mail_outline, size: 92, color: Colors.white),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggapan Undangan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$total undangan • $approved hadir, $rejected ditolak, $pending menunggu, $permission izin',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFFF7ED),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => InvitationResponsePage(
                                    eventId: currentEvent.eventId,
                                    eventName: currentEvent.nama,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFEA580C),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Kelola',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'DAFTAR KEHADIRAN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${attendanceList.length} Peserta',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (attendanceList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'Belum ada data kehadiran.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              else
                ...attendanceList.map((item) {
                  final name = item.displayName;
                  final role = item.role;
                  final time = item.time == null
                      ? '-'
                      : '${item.time!.hour.toString().padLeft(2, '0')}:${item.time!.minute.toString().padLeft(2, '0')} WIB';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserAvatar(name: name, radius: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(status: item.status),
                            const SizedBox(height: 4),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
