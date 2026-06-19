import 'package:flutter/material.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';
import 'package:b5_proyek_4/domain/models/attendance/permission_record.dart';
import 'package:b5_proyek_4/domain/models/event/event_invitation.dart';
import 'package:b5_proyek_4/domain/enums/status_enums.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PermissionFormView extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final VoidCallback onSuccessSubmit;

  const PermissionFormView({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.onSuccessSubmit,
  });

  @override
  State<PermissionFormView> createState() => _PermissionFormViewState();
}

class _PermissionFormViewState extends State<PermissionFormView> {
  String _selectedType = 'Sakit';
  bool _isLoading = false;
  String? _buktiFotoPath;
  final ImagePicker _picker = ImagePicker();
  String? _selectedEventId;

  static const List<String> _keteranganOptions = [
    'Sakit',
    'Izin',
    'Tidak Ada Alasan',
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _buktiFotoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitPermission() async {
    setState(() => _isLoading = true);

    try {
      final currentNim =
          AuthController.instance.currentUser.value?.nim ?? 'unknown';

      // 1. Validasi: Cegah izin jika sudah melakukan absensi (overlapping)
      final hasCheckedIn = HiveService.attendance.values.any(
        (r) => r.eventId == widget.eventId && r.nim == currentNim,
      );
      if (hasCheckedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda sudah melakukan absensi, tidak bisa mengajukan izin!'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // 2. Hubungkan ke EventInvitation (Cari atau buat jika belum ada)
      final invitationsBox = HiveService.invitations;
      EventInvitation? invitation;
      try {
        invitation = invitationsBox.values.firstWhere(
          (inv) => inv.eventId == widget.eventId && inv.nim == currentNim,
        );
      } catch (_) {
        invitation = EventInvitation(
          eventId: widget.eventId,
          nim: currentNim,
          responseStatus: 'permission_requested',
          attendanceTime: DateTime.now(),
          invitedBy: 'system',
          invitedAt: DateTime.now(),
          isSynced: false,
        );
      }

      // Update status respon undangan menjadi permissionRequested
      invitation.responseStatusEnum = InvitationStatus.permissionRequested;
      invitation.respondedAt = DateTime.now();
      invitation.isSynced = false;
      await invitationsBox.put(invitation.compositeKey, invitation);

      final permissionId = 'PERM-${DateTime.now().millisecondsSinceEpoch}';

      final newPermission = PermissionRecord(
        permissionId: permissionId,
        eventId: widget.eventId,
        nim: currentNim,
        jenisIzin: _selectedType.startsWith('Sakit') ? 'Sakit' : 'Izin',
        alasan: _selectedType,
        buktiFotoPath: _buktiFotoPath,
        status: 'Pending',
        isSynced: false,
      );

      // Simpan ke Hive
      await HiveService.permissions.put(permissionId, newPermission);

      widget.onSuccessSubmit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dikirim!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // event selection removed; form uses the event passed by the caller.

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.edit_document, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 12),
            Text(
              'Pengajuan Izin',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Tujuan
              const Text(
                'EVENT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.eventTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              ),
              const SizedBox(height: 16),

              // Keterangan
              const Text(
                'KETERANGAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ), // matching p-3 roughly
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    items: _keteranganOptions
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bukti
              const Text(
                'BUKTI (OPSIONAL)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: _buktiFotoPath != null
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(32),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                  child: _buktiFotoPath != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              File(_buktiFotoPath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    setState(() => _buktiFotoPath = null),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          children: [
                            Icon(
                              LucideIcons.upload,
                              size: 32,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Unggah File/Foto',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24), // mt-6
              // Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // bg-blue-600
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16), // py-4
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  elevation: 4, // shadow-md
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Pengajuan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
