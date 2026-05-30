import 'package:flutter/material.dart';
import '../models/event_invitation.dart';
import '../core/enums/status_enums.dart';

class InvitationCard extends StatelessWidget {
    final EventInvitation invitation;
    final String eventTitle;
    final String? penyelenggara;
    final VoidCallback onAccept;
    final VoidCallback onDecline;
    final VoidCallback onPermit;

    const InvitationCard({
        super.key,
        required this.invitation,
        required this.eventTitle,
        this.penyelenggara,
        required this.onAccept,
        required this.onDecline,
        required this.onPermit,
    });

    @override
    Widget build(BuildContext context) {
        bool isPending = invitation.responseStatusEnum == InvitationStatus.pending;

        return Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            Expanded(
                              child: Text(
                                  eventTitle,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                  ),
                              ),
                            ),
                            Chip(
                                label: Text(
                                    invitation.responseStatus.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                    ),
                                ),
                                backgroundColor: _getStatusColor(invitation.responseStatusEnum),
                            ),
                        ],
                    ),
                    if (penyelenggara != null && penyelenggara!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                                penyelenggara!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal,
                                ),
                            ),
                        ),
                    ],
                    const SizedBox(height: 16),

                    // Tombol aksi hanya muncul jika status masih pending
                    if (isPending)
                        Row(
                            children: [
                                Expanded(
                                    child: ElevatedButton(
                                        onPressed: onAccept,
                                        child: const Text('Setujui'),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: OutlinedButton(
                                        onPressed: onDecline,
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Tolak'),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: TextButton(
                                        onPressed: onPermit,
                                        child: const Text('Izin'),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
            ),
        );
    }

    Color _getStatusColor(InvitationStatus status) {
        switch (status) {
            case InvitationStatus.approved:
            case InvitationStatus.autoApproved:
                return Colors.green;
            case InvitationStatus.rejected:
                return Colors.red;
            case InvitationStatus.permissionRequested:
                return Colors.orange;
            default:
                return Colors.grey;
        }
    }
}