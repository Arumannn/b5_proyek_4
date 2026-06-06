import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/controllers/config_controller.dart';
import '../../../core/services/sync_manager.dart';
import '../../../core/widgets/inline_expanding_dropdown_field.dart';
import '../../../models/member_model.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../auth/auth_controller.dart';

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

  List<String> _dbuOptionsForRole(String role) {
    final fromBuilder = widget.dbuItemsBuilder(role);
    if (fromBuilder.isNotEmpty) {
      return fromBuilder;
    }
    return ConfigController.instance.dbuOptionsForRole(role);
  }

  @override
  void initState() {
    super.initState();
    SyncManager.instance.pullOrganizationConfigFromCloud();
    _nimController = TextEditingController(text: widget.existing?.nim ?? '');
    _namaController = TextEditingController(text: widget.existing?.nama ?? '');
    _passwordController = TextEditingController();

    final existingRole = (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
    final allRoles = ConfigController.instance.activeConfig.rolesConfig;
    debugPrint('[UserFormDialog][initState] existingRole: $existingRole, widget.existing.role: ${widget.existing?.role}');
    debugPrint('[UserFormDialog][initState] allRoles: ${allRoles.map((e) => '${e.roleName}:${e.jabatanList}').toList()}');
    
    if (allRoles.isEmpty) {
      _selectedRole = AppConstants.roleMember;
      debugPrint('[UserFormDialog][initState] allRoles is empty, fallback to: $_selectedRole');
    } else {
      final match = allRoles.where((e) => ConfigController.instance.roleMatchesConfiguredName(existingRole, e.roleName)).toList();
      if (match.isNotEmpty) {
        _selectedRole = match.first.roleName;
        debugPrint('[UserFormDialog][initState] match found for $existingRole: $_selectedRole');
      } else {
        _selectedRole = allRoles.first.roleName;
        debugPrint('[UserFormDialog][initState] no match found for $existingRole, fallback to first role: $_selectedRole');
      }
    }
    final dbuOptions = _dbuOptionsForRole(_selectedRole);
    final existingDbu = (widget.existing?.divisi ?? '').trim().toLowerCase();
    final dbuMatch = dbuOptions.where((d) => d.trim().toLowerCase() == existingDbu).toList();
    if (dbuMatch.isNotEmpty) {
      _selectedDbu = dbuMatch.first;
      debugPrint('[UserFormDialog][initState] dbuMatch found: $_selectedDbu');
    } else if (dbuOptions.isNotEmpty) {
      _selectedDbu = dbuOptions.first;
      debugPrint('[UserFormDialog][initState] no dbuMatch, fallback to first dbu: $_selectedDbu (existing: ${widget.existing?.divisi})');
    } else {
      _selectedDbu = 'Belum Ditentukan';
      debugPrint('[UserFormDialog][initState] dbuOptions is empty, fallback: $_selectedDbu');
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
                        ListenableBuilder(
                          listenable: ConfigController.instance,
                          builder: (context, _) {
                            final allRoles = ConfigController.instance.activeConfig.rolesConfig;
                            final roleOptions = allRoles.map((e) => e.roleName).toList();
                            
                            debugPrint('[UserFormDialog][BuilderRole] input _selectedRole: $_selectedRole, roleOptions: $roleOptions');
                            if (allRoles.isNotEmpty) {
                              final match = allRoles.where((e) => ConfigController.instance.roleMatchesConfiguredName(_selectedRole, e.roleName)).toList();
                              if (match.isNotEmpty) {
                                _selectedRole = match.first.roleName;
                                debugPrint('[UserFormDialog][BuilderRole] match/normalized: $_selectedRole');
                              } else if (!roleOptions.contains(_selectedRole)) {
                                if (_selectedRole.isNotEmpty) {
                                  roleOptions.add(_selectedRole);
                                  debugPrint('[UserFormDialog][BuilderRole] appending missing _selectedRole to options: $_selectedRole');
                                } else {
                                  _selectedRole = roleOptions.first;
                                  debugPrint('[UserFormDialog][BuilderRole] fallback to first role: $_selectedRole');
                                }
                              }
                            }
                            
                            return InlineExpandingDropdownField(
                              label: 'Role',
                              value: _selectedRole,
                              options: roleOptions,
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
                            );
                          }
                        ),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: ConfigController.instance,
                          builder: (context, _) {
                            final rawOptions = _dbuOptionsForRole(_selectedRole);
                            final validOptions = List<String>.from(rawOptions);
                            
                            debugPrint('[UserFormDialog][BuilderDBU] input _selectedDbu: $_selectedDbu, _selectedRole: $_selectedRole, rawOptions: $rawOptions');
                            if (_selectedDbu.isNotEmpty) {
                              final dbuMatch = validOptions.where((d) => d.trim().toLowerCase() == _selectedDbu.trim().toLowerCase()).toList();
                              if (dbuMatch.isNotEmpty) {
                                _selectedDbu = dbuMatch.first;
                                debugPrint('[UserFormDialog][BuilderDBU] matched case-insensitive: $_selectedDbu');
                              } else {
                                validOptions.add(_selectedDbu);
                                debugPrint('[UserFormDialog][BuilderDBU] DBU $_selectedDbu not in config, dynamically appended to options!');
                              }
                            } else if (validOptions.isNotEmpty) {
                              _selectedDbu = validOptions.first;
                              debugPrint('[UserFormDialog][BuilderDBU] fallback first: $_selectedDbu');
                            }
                            
                            return InlineExpandingDropdownField(
                              label: 'Departemen/Biro/Unit (DBU)',
                              value: _selectedDbu,
                              options: validOptions,
                              placeholder: 'Pilih DBU',
                              onChanged: (value) {
                                setState(() {
                                  _selectedDbu = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || !validOptions.contains(value)) {
                                  return 'DBU wajib dipilih.';
                                }
                                return null;
                              },
                            );
                          }
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
