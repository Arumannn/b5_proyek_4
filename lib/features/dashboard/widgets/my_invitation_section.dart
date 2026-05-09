import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/event_invitation.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../widgets/invitation_card.dart';
import '../../member/permission_form_view.dart';

class MyInvitationSection extends StatelessWidget {
    final String currentMemberId;

    const MyInvitationSection({
        super.key,
        required this.currentMemberId,
    });

    // Fungsi untuk menangani perubahan status undangan
    Future<void> _handleInvitationResponse(
        BuildContext context,
        EventInvitation invitation,
        String newStatus,
    ) async {
        try {
            // Update status di Hive
            invitation.responseStatus = newStatus;
            invitation.respondedAt = DateTime.now();
            invitation.isSynced = false;

            // Simpan kembali ke Hive
            await HiveService.invitations.put(invitation.invitationId, invitation);

            CustomSnackbar.showSuccess(context, 'Response updated to $newStatus');
        } catch (e) {
            CustomSnackbar.showError(context, 'Failed to update response: $e');
        }
    }

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text(
                    'Undangan Saya',
                    style: TextStyle(fontSize: 18,  fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                //Memantau perubahan data di dalam box undangan secara real-time
                ValueListenableBuilder(
                    valueListenable: HiveService.invitations.listenable(),
                    builder: (context, box, _) {
                        //1. Ambil semua undangan yang ditujukan untuk user yang sedang login
                        final myInvitations = box.values
                            .where((inv) => inv.memberId == currentMemberId)
                            .toList();

                        if (myInvitations.isEmpty) {
                            return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                    child: Text('Belum ada undangan yang masuk'),
                                ),
                            );
                        }

                        //2. Tampilkan daftar undangan
                        return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: myInvitations.length,
                            itemBuilder: (context, index) {
                                final invitation = myInvitations[index];

                                // Ambil judul event dari Hive berdasarkan eventId di undangan
                                final event = HiveService.events.get(invitation.eventId);
                                final eventTitle = event?.nama ?? 'Event Tidak Ditemukan';

                                return InvitationCard(
                                    invitation: invitation,
                                    eventTitle: eventTitle,
                                    onAccept: () => _handleInvitationResponse(
                                        context,
                                        invitation,
                                        'approved',
                                    ),
                                    onDecline: () => _handleInvitationResponse(
                                        context,
                                        invitation,
                                        'decline',
                                    ),
                                    onPermit: () {
                                        // Navigate to permission form
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => PermissionFormView(
                                                    eventId: invitation.eventId,
                                                    eventTitle: eventTitle,
                                                    onSuccessSubmit: () {
                                                        // Update invitation status after permission submitted
                                                        _handleInvitationResponse(
                                                            context,
                                                            invitation,
                                                            'permission_requested',
                                                        );
                                                    },
                                                ),
                                            ),
                                        );
                                    },
                                );
                            },
                        );
                    }
                ),
            ],
        );
    }
}