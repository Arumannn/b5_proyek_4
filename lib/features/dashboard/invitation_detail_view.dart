import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/hive_service.dart';
import '../../../models/event_invitation.dart';
import '../member/permission_form_view.dart';
import '../../widgets/custom_snackbar.dart';
import '../../../core/enums/status_enums.dart';

class InvitationDetailView extends StatefulWidget {
  final EventInvitation invitation;
  final String eventTitle;

  const InvitationDetailView({
    super.key,
    required this.invitation,
    required this.eventTitle,
  });

  @override
  State<InvitationDetailView> createState() => _InvitationDetailViewState();
}

class _InvitationDetailViewState extends State<InvitationDetailView> {
  
  Future<void> _handleInvitationResponse(InvitationStatus newStatus) async {
    try {
      widget.invitation.responseStatusEnum = newStatus;
      widget.invitation.respondedAt = DateTime.now();
      widget.invitation.isSynced = false;
      await HiveService.invitations.put(widget.invitation.invitationId, widget.invitation);
      if (!mounted) return;
      CustomSnackbar.showSuccess(context, 'Respon berhasil diperbarui');
      if (newStatus != InvitationStatus.permissionRequested) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.showError(context, 'Gagal memperbarui respon: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = HiveService.events.get(widget.invitation.eventId);
    if (event == null) {
      return const Scaffold(body: Center(child: Text('Event tidak ditemukan')));
    }
    
    final targetDate = event.tanggalMulai;
    final dateStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(targetDate);
    final startTime = event.jamMulai ?? targetDate;
    final endTime = event.jamSelesai ?? event.tanggalSelesai ?? targetDate.add(const Duration(hours: 2));
    
    final startTimeStr = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final endTimeStr = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')} WIB";
    final location = event.lokasi?.isNotEmpty == true ? event.lokasi! : 'Lokasi Belum Ditentukan';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Undangan', style: TextStyle(color: Color(0xFF1F2937), fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7), // amber-100
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mail_outline, size: 56, color: Color(0xFFF59E0B)), // amber-500
                ),
              ),
              const SizedBox(height: 32),
              
              // Title & Subtitle
              Text(
                widget.eventTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pengurus mengundang Anda untuk hadir pada event ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 32),
              
              // Details Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // gray-50
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F4F6)), // gray-100
                ),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.calendar_today, 'Tanggal', dateStr),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.access_time, 'Waktu', '$startTimeStr - $endTimeStr'),
                    const SizedBox(height: 16),
                    _buildDetailRow(Icons.location_on_outlined, 'Lokasi', location),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Divider(color: Color(0xFFF3F4F6), thickness: 1),
              const SizedBox(height: 24),
              
              // Question
              const Text(
                'Apakah Anda bersedia hadir?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 16),
              
              // Buttons
              ElevatedButton(
                onPressed: () => _handleInvitationResponse(InvitationStatus.approved),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A), // green-600
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shadowColor: const Color(0xFFBBF7D0), // green-200
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: 20),
                    SizedBox(width: 8),
                    Text('Ya, Saya Akan Hadir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PermissionFormView(
                    eventId: widget.invitation.eventId, 
                    eventTitle: widget.eventTitle,
                    onSuccessSubmit: () {
                      // Ini dijalankan jika permission form view disubmit
                      widget.invitation.responseStatusEnum = InvitationStatus.permissionRequested;
                      widget.invitation.respondedAt = DateTime.now();
                      widget.invitation.isSynced = false;
                      HiveService.invitations.put(widget.invitation.invitationId, widget.invitation);
                    }
                  )));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEA580C), // orange-600
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFFEDD5), width: 2), // orange-100
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.close, size: 20),
                    SizedBox(width: 8),
                    Text('Tidak, Ajukan Izin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3B82F6)), // blue-500
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF), letterSpacing: 0.5), // gray-400
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)), // gray-800
              ),
            ],
          ),
        ),
      ],
    );
  }
}
