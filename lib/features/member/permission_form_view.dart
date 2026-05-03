import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:b5_proyek_4/features/auth/auth_controller.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';

class PermissionFormView extends StatefulWidget {
  const PermissionFormView({super.key});

  @override
  State<PermissionFormView> createState() => _PermissionFormViewState();
}

class _PermissionFormViewState extends State<PermissionFormView> {
  // UI State Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _alasanController = TextEditingController();
  
  String? _selectedEventId;
  String _jenisIzin = 'Izin'; // Default value
  File? _selectedImage;

  // Mock Data Event (Nanti ini diambil dari EventController.events.value)
  final List<Map<String, String>> _dummyEvents = [
    {'id': 'evt-1', 'nama': 'Rapat Pleno HIMAKOM'},
    {'id': 'evt-2', 'nama': 'Kaderisasi Tahap 1'},
  ];

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuka Kamera / Galeri
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70, // Kompres ukuran agar tidak berat di Hive/Firebase
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Gagal mengambil gambar: $e');
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

void _submitForm() {
  if (_formKey.currentState!.validate()) {
    final currentNim = AuthController.instance.currentUser.value?.nim;
    
    final isAlreadySubmitted = HiveService.permissions.values.any(
      (p) => p.eventId == _selectedEventId && p.nim == currentNim
    );

    if (isAlreadySubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah mengajukan izin untuk event ini!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

      // TODO: Panggil PermissionController di sini nantinya
      // PermissionController.instance.submitPermission(
      //   eventId: _selectedEventId!,
      //   jenisIzin: _jenisIzin,
      //   alasan: _alasanController.text,
      //   buktiFotoPath: _selectedImage!.path,
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode UI: Form valid. Menunggu Controller Backend.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientHeader(title: 'Pengajuan Izin / Sakit', subtitle: 'Form pengajuan anggota'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Pilih Event
              const Text('Pilih Event', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Pilih event yang tidak bisa dihadiri'),
                value: _selectedEventId,
                items: _dummyEvents.map((e) {
                  return DropdownMenuItem<String>(
                    value: e['id'],
                    child: Text(e['nama']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedEventId = val),
                validator: (val) => val == null ? 'Pilih event terlebih dahulu' : null,
              ),
              const SizedBox(height: 20),

              // 2. Jenis Izin (Radio Buttons)
              const Text('Jenis Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Izin'),
                      value: 'Izin',
                      groupValue: _jenisIzin,
                      onChanged: (val) => setState(() => _jenisIzin = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Sakit'),
                      value: 'Sakit',
                      groupValue: _jenisIzin,
                      onChanged: (val) => setState(() => _jenisIzin = val!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Alasan
              const Text('Alasan Detail', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tuliskan alasan lengkapmu di sini...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty 
                    ? 'Alasan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // 4. Bukti Foto (UI Kotak Upload)
              const Text('Bukti Foto (Surat Dokter/Lainnya)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showImagePickerModal,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Ketuk untuk upload foto', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),

              // 5. Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _submitForm,
                  child: const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}