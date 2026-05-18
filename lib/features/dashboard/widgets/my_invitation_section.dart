import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/event_invitation.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../member/permission_form_view.dart';

class MyInvitationSection extends StatelessWidget {
  final String currentNim;

  const MyInvitationSection({
    super.key,
    required this.currentNim,
  });

  Future<void> _handleInvitationResponse(BuildContext context, EventInvitation invitation, String newStatus) async {
    try {
      invitation.responseStatus = newStatus;
      invitation.respondedAt = DateTime.now();
      invitation.isSynced = false;
      await HiveService.invitations.put(invitation.invitationId, invitation);
      if (!context.mounted) return;
      CustomSnackbar.showSuccess(context, 'Respon berhasil diperbarui');
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.showError(context, 'Gagal memperbarui respon: $e');
    }
  }

@override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.invitations.listenable(),
      builder: (context, box, _) {
        final myInvitations = box.values
          .where((inv) => inv.nim == currentNim)
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

        // Tampilkan undangan teratas
        final invitation = myInvitations.first;
        final event = HiveService.events.get(invitation.eventId);
        
        // Antisipasi jika data event null saat pemanggilan darurat
        final eventName = event?.nama ?? 'Undangan Kegiatan';
        final targetDate = event?.tanggalMulai ?? DateTime.now(); 
        final startTime = event?.jamMulai ?? targetDate;

        final timeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} WIB";
        final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(targetDate);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.mail_rounded, size: 120, color: Colors.white.withValues(alpha: 0.2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                      child: const Text('UNDANGAN BARU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                    const SizedBox(height: 12),
                    Text(eventName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text('$dateStr • $timeStr', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(context, invitation, eventName);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEA580C),
                        minimumSize: const Size(140, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Lihat & Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(BuildContext context, EventInvitation invitation, String eventTitle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline, size: 48, color: Colors.amber),
              const SizedBox(height: 16),
              const Text('Konfirmasi Kehadiran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Apakah Anda bersedia hadir pada kegiatan $eventTitle?', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleInvitationResponse(context, invitation, 'approved');
                },
                icon: const Icon(Icons.check),
                label: const Text('Ya, Saya Akan Hadir'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PermissionFormView(
                    eventId: invitation.eventId, 
                    eventTitle: eventTitle,
                    onSuccessSubmit: () {
                      // Status undangan akan terupdate menjadi permission_requested setelah izin dikirim
                      _handleInvitationResponse(context, invitation, 'permission_requested');
                    }
                  )));
                },
                icon: const Icon(Icons.close),
                label: const Text('Tidak, Ajukan Izin'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}