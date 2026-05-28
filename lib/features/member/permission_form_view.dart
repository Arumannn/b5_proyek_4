import 'package:flutter/material.dart';
import '../../core/services/hive_service.dart';
import '../auth/auth_controller.dart';
import '../../models/permission_record.dart';
import '../../widgets/white_status_header.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
  String _selectedType = 'Sakit (Lampirkan Surat)';
  bool _isLoading = false;

  Future<void> _submitPermission() async {
    setState(() => _isLoading = true);

    try {
      final currentNim = AuthController.instance.currentUser.value?.nim ?? 'unknown';

      final permissionId = 'PERM-${DateTime.now().millisecondsSinceEpoch}';

      final newPermission = PermissionRecord(
        permissionId: permissionId,
        eventId: widget.eventId,
        nim: currentNim,
        jenisIzin: _selectedType.startsWith('Sakit') ? 'Sakit' : 'Izin',
        alasan: _selectedType,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WhiteStatusHeader(
        title: 'Pengajuan Izin',
        subtitle: 'Isi formulir di bawah ini',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Tujuan
              const Text(
                'PILIH EVENT/KEGIATAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151), // gray-700
                  letterSpacing: 0.5, // tracking-wide
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), // gray-50
                  border: Border.all(color: const Color(0xFFE5E7EB)), // gray-200
                  borderRadius: BorderRadius.circular(12), // rounded-xl
                ),
                child: Text(
                  widget.eventTitle,
                  style: const TextStyle(
                    fontSize: 14, // text-sm
                    color: Color(0xFF1F2937), // gray-800
                  ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2), // matching p-3 roughly
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sakit (Lampirkan Surat)',
                        child: Text('Sakit (Lampirkan Surat)'),
                      ),
                      DropdownMenuItem(
                        value: 'Izin - Urusan Akademik/Kuliah',
                        child: Text('Izin - Urusan Akademik/Kuliah'),
                      ),
                      DropdownMenuItem(
                        value: 'Izin - Keperluan Keluarga',
                        child: Text('Izin - Keperluan Keluarga'),
                      ),
                    ],
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
                onTap: () {
                  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload fitur akan segera hadir')));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32), // p-8
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB), // bg-gray-50
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                    // Using solid border, dashed border needs custom painter or package
                    border: Border.all(color: const Color(0xFFD1D5DB), width: 2), // border-2 border-gray-300
                  ),
                  child: const Column(
                    children: [
                      Icon(LucideIcons.upload, size: 32, color: Color(0xFF9CA3AF)), // gray-400
                      SizedBox(height: 8), // mb-2
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
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