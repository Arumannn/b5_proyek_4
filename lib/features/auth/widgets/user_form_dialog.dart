import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/config_controller.dart';
import '../../../core/widgets/inline_expanding_dropdown_field.dart';
import '../../../models/member_model.dart';
import '../../../widgets/custom_snackbar.dart';
import '../auth_controller.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({
    super.key,
    required this.authController,
    required this.roleLabelBuilder,
    required this.dbuItemsBuilder,
    this.existing,
  });

  final AuthController authController;
  final MemberModel? existing;
  final String Function(String role) roleLabelBuilder;
  final List<String> Function(String role) dbuItemsBuilder;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
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

    final existingRole = (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    final success = _isEdit
        ? await widget.authController.updateUserByExecutive(
            nim: widget.existing!.nim,
            nama: _namaController.text,
            divisi: _selectedDbu,
            role: _selectedRole,
            password: _passwordController.text,
          )
        : await widget.authController.createUserByExecutive(
            nama: _namaController.text,
            nim: _nimController.text,
            divisi: _selectedDbu,
            role: _selectedRole,
            password: _passwordController.text,
          );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isSaving = false;
    });
    CustomSnackbar.showError(
      context,
      widget.authController.errorMessage.value ?? 'Gagal menyimpan data anggota.',
    );
  }

  Widget _buildFieldLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _isSaving ? null : () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdit ? 'Edit Anggota' : 'Tambah Anggota',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFieldLabel('NIM'),
                        TextFormField(
                          controller: _nimController,
                          enabled: !_isEdit,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(hintText: 'Masukkan NIM'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'NIM wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFieldLabel('Nama'),
                        TextFormField(
                          controller: _namaController,
                          decoration: _inputDecoration(hintText: 'Masukkan nama anggota'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InlineExpandingDropdownField(
                          label: 'Role',
                          value: _selectedRole,
                          options: AppConstants.allowedRoles,
                          placeholder: 'Pilih role',
                          itemLabelBuilder: widget.roleLabelBuilder,
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                              _selectedDbu = ConfigController.instance.defaultDbuForRole(value);
                            });
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Role wajib dipilih.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        InlineExpandingDropdownField(
                          label: 'Departemen/Biro/Unit (DBU)',
                          value: _selectedDbu,
                          options: widget.dbuItemsBuilder(_selectedRole),
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
                        const SizedBox(height: 12),
                        _buildFieldLabel('Password'),
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _submit,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined, color: Colors.white),
                            label: Text(
                              _isEdit ? 'Simpan Perubahan' : 'Simpan Anggota',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 6,
                              shadowColor: const Color(0xFF93C5FD),
                            ),
                          ),
                        ),
                      ],
                    ),
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
