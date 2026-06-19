import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';
import 'package:b5_proyek_4/data/services/sync_manager.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/inline_expanding_dropdown_field.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/presentation/widgets/shared/custom_snackbar.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';

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
    SyncManager.instance.pullOrganizationConfigFromCloud();
    _nimController = TextEditingController(text: widget.existing?.nim ?? '');
    _namaController = TextEditingController(text: widget.existing?.nama ?? '');
    _passwordController = TextEditingController();

    final existingRole =
        (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
    final allRoles = ConfigController.instance.activeConfig.rolesConfig;
    debugPrint('[MemberForm][initState] existingRole: $existingRole, widget.existing.role: ${widget.existing?.role}');
    debugPrint('[MemberForm][initState] allRoles: ${allRoles.map((e) => '${e.roleName}:${e.jabatanList}').toList()}');
    
    if (allRoles.isEmpty) {
      _selectedRole = AppConstants.roleMember;
      debugPrint('[MemberForm][initState] allRoles is empty, fallback to: $_selectedRole');
    } else {
      final match = allRoles.where((e) => ConfigController.instance.roleMatchesConfiguredName(existingRole, e.roleName)).toList();
      if (match.isNotEmpty) {
        _selectedRole = match.first.roleName;
        debugPrint('[MemberForm][initState] match found for $existingRole: $_selectedRole');
      } else {
        _selectedRole = allRoles.first.roleName;
        debugPrint('[MemberForm][initState] no match found for $existingRole, fallback to first role: $_selectedRole');
      }
    }
    
    final dbuOptions = ConfigController.instance.dbuOptionsForRole(_selectedRole);
    final existingDbu = (widget.existing?.divisi ?? '').trim().toLowerCase();
    final dbuMatch = dbuOptions.where((d) => d.trim().toLowerCase() == existingDbu).toList();
    if (dbuMatch.isNotEmpty) {
      _selectedDbu = dbuMatch.first;
      debugPrint('[MemberForm][initState] dbuMatch found: $_selectedDbu');
    } else if (dbuOptions.isNotEmpty) {
      _selectedDbu = dbuOptions.first;
      debugPrint('[MemberForm][initState] no dbuMatch, fallback to first dbu: $_selectedDbu (existing: ${widget.existing?.divisi})');
    } else {
      _selectedDbu = 'Belum Ditentukan';
      debugPrint('[MemberForm][initState] dbuOptions is empty, fallback: $_selectedDbu');
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
    // Gunakan nama asli dari konfigurasi, atau fallback capitalize
    final matchingRole = ConfigController.instance.activeConfig.rolesConfig
        .where((r) => r.roleName.toLowerCase() == role.trim().toLowerCase())
        .toList();
    if (matchingRole.isNotEmpty) {
      return matchingRole.first.roleName;
    }
    if (role.isEmpty) return 'Member';
    return '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}';
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
            password: _passwordController.text.trim().isEmpty ? null : _passwordController.text,
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
              ListenableBuilder(
                listenable: ConfigController.instance,
                builder: (context, _) {
                  // Ensure selected role is still valid and normalized
                  final allRoles = ConfigController.instance.activeConfig.rolesConfig;
                  final roleOptions = allRoles.map((e) => e.roleName).toList();
                  
                  debugPrint('[MemberForm][BuilderPeran] input _selectedRole: $_selectedRole, roleOptions: $roleOptions');
                  if (allRoles.isNotEmpty) {
                    final match = allRoles.where((e) => ConfigController.instance.roleMatchesConfiguredName(_selectedRole, e.roleName)).toList();
                    if (match.isNotEmpty) {
                      _selectedRole = match.first.roleName;
                      debugPrint('[MemberForm][BuilderPeran] match/normalized: $_selectedRole');
                    } else if (!roleOptions.contains(_selectedRole)) {
                      if (_selectedRole.isNotEmpty) {
                        roleOptions.add(_selectedRole);
                        debugPrint('[MemberForm][BuilderPeran] appending missing _selectedRole to options: $_selectedRole');
                      } else {
                        _selectedRole = roleOptions.first;
                        debugPrint('[MemberForm][BuilderPeran] fallback to first role: $_selectedRole');
                      }
                    }
                  }
                  
                  return InlineExpandingDropdownField(
                    label: 'Peran (Role Sistem)',
                    value: _selectedRole,
                    options: roleOptions,
                    placeholder: 'Pilih role',
                    itemLabelBuilder: _roleLabel,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        _selectedDbu = ConfigController.instance.defaultDbuForRole(value);
                      });
                    },
                  );
                }
              ),
              const SizedBox(height: 16),

              ListenableBuilder(
                listenable: ConfigController.instance,
                builder: (context, _) {
                  final rawOptions = ConfigController.instance.dbuOptionsForRole(_selectedRole);
                  final validOptions = List<String>.from(rawOptions);
                  
                  debugPrint('[MemberForm][BuilderDBU] input _selectedDbu: $_selectedDbu, _selectedRole: $_selectedRole, rawOptions: $rawOptions');
                  if (_selectedDbu.isNotEmpty) {
                    final dbuMatch = validOptions.where((d) => d.trim().toLowerCase() == _selectedDbu.trim().toLowerCase()).toList();
                    if (dbuMatch.isNotEmpty) {
                      _selectedDbu = dbuMatch.first;
                      debugPrint('[MemberForm][BuilderDBU] matched case-insensitive: $_selectedDbu');
                    } else {
                      validOptions.add(_selectedDbu);
                      debugPrint('[MemberForm][BuilderDBU] DBU $_selectedDbu not in config, dynamically appended to options!');
                    }
                  } else if (validOptions.isNotEmpty) {
                    _selectedDbu = validOptions.first;
                    debugPrint('[MemberForm][BuilderDBU] fallback first: $_selectedDbu');
                  }
                  
                  return InlineExpandingDropdownField(
                    label: 'Jabatan / Departemen (DBU)',
                    value: _selectedDbu,
                    options: validOptions,
                    placeholder: 'Pilih Jabatan/Departemen',
                    onChanged: (value) {
                      setState(() {
                        _selectedDbu = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || !validOptions.contains(value)) {
                        return 'Jabatan/Departemen wajib dipilih.';
                      }
                      return null;
                    },
                  );
                }
              ),
              const SizedBox(height: 16),

              // Password
              _buildInputLabel(_isEdit ? 'Password (Kosongkan jika tidak ingin diubah)' : 'Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration(hintText: _isEdit ? 'Biarkan kosong untuk mempertahankan password lama' : 'Masukkan password'),
                validator: (value) {
                  if (!_isEdit && (value == null || value.trim().isEmpty)) {
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
