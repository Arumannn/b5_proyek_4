import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/hive_service.dart';
import '../invitation_detail_view.dart';

class MyInvitationSection extends StatelessWidget {
  final String currentNim;

  const MyInvitationSection({
    super.key,
    required this.currentNim,
  });

@override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService.invitations.listenable(),
      builder: (context, box, _) {
        final myInvitations = box.values.where((inv) {
          if (inv.nim.trim() != currentNim.trim()) return false;

          final status = inv.responseStatus.trim().toLowerCase();
          if (status != 'pending') return false;

          final event = HiveService.events.get(inv.eventId);
          if (event == null || event.isDeleted) return false;
          
          final eventStatus = event.statusEvent.toLowerCase();
          if (eventStatus == 'selesai' || eventStatus.contains('arsip') || eventStatus == 'batal') return false;
          
          return true;
        }).toList();

        if (myInvitations.isEmpty) return const SizedBox.shrink();

        myInvitations.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));

        // Tampilkan undangan teratas
        final invitation = myInvitations.first;
        final event = HiveService.events.get(invitation.eventId)!;
        
        final eventName = event.nama;
        final targetDate = event.tanggalMulai;
        final startTime = event.jamMulai ?? targetDate;
        
        final timeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} WIB";
        final dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(targetDate);

        return Container(
          margin: const EdgeInsets.only(bottom: 24), // matching space-y-6 roughly
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)], // from-amber-500 to-orange-500
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16), // rounded-2xl roughly
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)), // shadow-lg
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                right: -16, // -right-4
                top: -16, // -top-4
                child: Icon(Icons.mail_outline, size: 100, color: Colors.white.withValues(alpha: 0.2)),
              ),
              Padding(
                padding: const EdgeInsets.all(20), // p-5
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // px-2 py-1
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), // bg-white/20
                        borderRadius: BorderRadius.circular(4), // rounded
                      ),
                      child: const Text(
                        'UNDANGAN BARU', // uppercase
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5, // tracking-wide
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(eventName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4), // mb-4
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange.shade100, size: 12),
                        const SizedBox(width: 4), // mr-1
                        Text('$dateStr • $timeStr', style: TextStyle(color: Colors.orange.shade100, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => InvitationDetailView(
                            invitation: invitation,
                            eventTitle: eventName,
                          ),
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEA580C), // text-orange-600
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // px-4 py-2
                        minimumSize: const Size(0, 36), // Ensures it's compact
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 1, // shadow-sm
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // rounded-lg
                      ),
                      child: const Text('Lihat & Konfirmasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // text-sm font-bold
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
}