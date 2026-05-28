import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';
import '../../core/widgets/inline_expanding_dropdown_field.dart';
import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../auth/auth_controller.dart';

class MemberFormView extends StatefulWidget {
  final MemberModel? existing;

  const MemberFormView({super.key, this.existing});

  @override
  State<MemberFormView> createState() => _MemberFormViewState();
}

class _MemberFormViewState extends State<MemberFormView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nimController;
  late final TextEditingController _namaController;
  late final TextEditingController _passwordController;

  late String _selectedRole;
  late String _selectedDbu;
  bool _isSaving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nimController = TextEditingController(text: widget.existing?.nim ?? '');
    _namaController = TextEditingController(text: widget.existing?.nama ?? '');
    _passwordController = TextEditingController();

    final existingRole =
        (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
    _selectedRole = AppConstants.allowedRoles.firstWhere(
      (role) => role.trim().toLowerCase() == existingRole,
      orElse: () => AppConstants.roleMember,
    );
    final dbuOptions = ConfigController.instance.dbuOptionsForRole(_selectedRole);
    _selectedDbu = widget.existing?.divisi ?? dbuOptions.first;
    if (!dbuOptions.contains(_selectedDbu)) {
      _selectedDbu = dbuOptions.first;
    }
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == AppConstants.roleExecutive.toLowerCase()) {
      return 'Eksekutif';
    }
    if (normalized == AppConstants.roleManager) return 'Manager';
    if (normalized == AppConstants.roleOrganizer) return 'Organizer';
    return 'Member';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = _isEdit
        ? await AuthController.instance.updateUserByExecutive(
            nim: widget.existing!.nim,
            nama: _namaController.text,
            divisi: _selectedDbu,
            role: _selectedRole,
        password: _passwordController.text,
          )
        : await AuthController.instance.createUserByExecutive(
            nama: _namaController.text,
            nim: _nimController.text,
            divisi: _selectedDbu,
            role: _selectedRole,
            password: _passwordController.text,
          );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      CustomSnackbar.showSuccess(
        context,
        _isEdit ? 'Data anggota berhasil diperbarui.' : 'Data anggota berhasil ditambahkan.',
      );
      Navigator.of(context).pop(true);
      return;
    }

    CustomSnackbar.showError(
      context,
      AuthController.instance.errorMessage.value ?? 'Gagal menyimpan data anggota.',
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6), // mb-1 equivalent
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10, // text-xs
          fontWeight: FontWeight.bold,
          color: Colors.grey[700], // text-gray-700
          letterSpacing: 0.5, // tracking-wide
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50], // bg-gray-50
      contentPadding: const EdgeInsets.all(14), // p-3.5
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // rounded-xl
        borderSide: BorderSide(color: Colors.grey[200]!), // border-gray-200
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2), // focus:ring-blue-500
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // bg-white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Anggota' : 'Tambah Anggota',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200], // border-b border-gray-200
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16), // p-4
            children: [
              // Nama Lengkap
              _buildInputLabel('Nama Lengkap'),
              TextFormField(
                controller: _namaController,
                decoration: _inputDecoration(hintText: 'Masukkan nama lengkap'),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16), // space-y-4

              // NIM
              _buildInputLabel('NIM (Nomor Induk Mahasiswa)'),
              TextFormField(
                controller: _nimController,
                enabled: !_isEdit,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(hintText: 'Contoh: 123456789'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'NIM wajib diisi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Peran (Role Sistem)
              InlineExpandingDropdownField(
                label: 'Peran (Role Sistem)',
                value: _selectedRole,
                options: AppConstants.allowedRoles,
                placeholder: 'Pilih role',
                itemLabelBuilder: _roleLabel,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value;
                    _selectedDbu = ConfigController.instance.defaultDbuForRole(value);
                  });
                },
              ),
              const SizedBox(height: 16),

              InlineExpandingDropdownField(
                label: 'Departemen/Biro/Unit (DBU)',
                value: _selectedDbu,
                options: ConfigController.instance.dbuOptionsForRole(_selectedRole),
                placeholder: 'Pilih DBU',
                onChanged: (value) {
                  setState(() {
                    _selectedDbu = value;
                  });
                },
                validator: (value) {
                  final validOptions = ConfigController.instance.dbuOptionsForRole(_selectedRole);
                  if (value == null || !validOptions.contains(value)) {
                    return 'DBU wajib dipilih.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              _buildInputLabel('Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration(hintText: 'Masukkan password'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Password wajib diisi.';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24), // mt-6

              // Tombol Simpan
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB), // bg-blue-600
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16), // py-4
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                  elevation: 4, // shadow-lg
                  shadowColor: const Color(0xFFBFDBFE), // shadow-blue-200
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.save, size: 18), // Save size={18}
                    const SizedBox(width: 8), // mr-2
                    Text(
                      _isSaving ? 'Menyimpan...' : 'Simpan Data Anggota',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40), // pb-24 padding inside list
            ],
          ),
        ),
      ),
    );
  }
}
