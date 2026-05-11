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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pantauan Undangan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Approved', approved, Colors.green),
                      _buildStatItem('Rejected', rejected, Colors.red),
                      _buildStatItem('Pending', pending, Colors.grey),
                      _buildStatItem('Izin', permission, Colors.orange),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daftar Respons Peserta',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invitations.length,
                    itemBuilder: (context, index) {
                      final invitation = invitations[index];
                      final member = HiveService.members.get(invitation.nim);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _getStatusColor(invitation.responseStatus)
                                  .withValues(alpha: 0.18),
                              child: Text(
                                (member?.nama.isNotEmpty ?? false) ? member!.nama[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: _getStatusColor(invitation.responseStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member?.nama ?? 'Unknown Member',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    invitation.responseStatus.replaceAll('_', ' '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            invitation.responseStatus == 'permission_requested'
                                ? ElevatedButton(
                                    onPressed: () => _showPermissionApprovalDialog(
                                      context,
                                      invitation,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF59E0B),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Cek Izin',
                                      style: TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                  )
                                : Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: _getStatusColor(invitation.responseStatus),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
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
            p.nim == invitation.nim)
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
