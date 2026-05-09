import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hive_service.dart';
import '../../models/event_invitation.dart';

class InvitationMonitoringSection extends StatelessWidget {
  final String eventId;

  const InvitationMonitoringSection({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<EventInvitation>>(
      valueListenable: HiveService.invitations.listenable(),
      builder: (context, box, _) {
        final invitations = box.values
            .where((inv) => inv.eventId == eventId)
            .toList();

        if (invitations.isEmpty) {
          return const Center(
            child: Text('Tidak ada peserta yang diundang secara khusus.'),
          );
        }

        // --- CALCULATE STATISTICS ---
        int approved = invitations
            .where((inv) =>
                inv.responseStatus == 'approved' ||
                inv.responseStatus == 'auto-approved')
            .length;
        int rejected =
            invitations.where((inv) => inv.responseStatus == 'rejected').length;
        int pending =
            invitations.where((inv) => inv.responseStatus == 'pending').length;
        int permission = invitations
            .where((inv) => inv.responseStatus == 'permission_requested')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pantauan Undangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // --- STATISTICS SUMMARY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Approved', approved, Colors.green),
                _buildStatItem('Rejected', rejected, Colors.red),
                _buildStatItem('Pending', pending, Colors.grey),
                _buildStatItem('Izin', permission, Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // --- PARTICIPANT LIST ---
            const Text(
              'Daftar Respons Peserta:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                final member = HiveService.members.get(invitation.memberId);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(invitation.responseStatus)
                          .withValues(alpha: 0.2),
                      child: Text(
                        member?.nama[0] ?? '?',
                        style: TextStyle(
                          color: _getStatusColor(invitation.responseStatus),
                        ),
                      ),
                    ),
                    title: Text(member?.nama ?? 'Unknown Member'),
                    subtitle:
                        Text(invitation.responseStatus.replaceAll('_', ' ')),
                    trailing:
                        invitation.responseStatus == 'permission_requested'
                            ? ElevatedButton(
                                onPressed: () =>
                                    _showPermissionApprovalDialog(
                                      context,
                                      invitation,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: const Text(
                                  'Cek Izin',
                                  style: TextStyle(fontSize: 11),
                                ),
                              )
                            : Icon(
                                Icons.circle,
                                size: 12,
                                color: _getStatusColor(
                                  invitation.responseStatus,
                                ),
                              ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'auto-approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'permission_requested':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // --- PERMISSION APPROVAL DIALOG ---

  void _showPermissionApprovalDialog(
    BuildContext context,
    EventInvitation invitation,
  ) {
    // Get permission records for this invitation
    final permissionRecords = HiveService.permissions.values
        .where((p) =>
            p.eventId == invitation.eventId &&
            p.memberId == invitation.memberId)
        .toList();

    final reason = permissionRecords.isNotEmpty
        ? permissionRecords.last.alasan
        : "Tidak ada alasan terlampir.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validasi Izin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alasan Peserta:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reason,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                _updatePermissionStatus(invitation, 'rejected', context),
            child: const Text(
              'Tolak Izin',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () =>
                _updatePermissionStatus(invitation, 'permission', context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Setujui Izin'),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePermissionStatus(
    EventInvitation invitation,
    String status,
    BuildContext context,
  ) async {
    try {
      // If approved, set attendance status to 'permission'
      // If rejected, keep response status as 'approved' (mandatory attendance)
      if (status == 'permission') {
        invitation.attendanceStatus = 'permission';
        invitation.responseStatus = 'approved'; // Mark permission as processed
      } else {
        invitation.responseStatus = 'approved'; // Rejected, still mandatory
      }

      invitation.isSynced = false;
      await HiveService.invitations.put(invitation.invitationId, invitation);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status izin diperbarui.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
