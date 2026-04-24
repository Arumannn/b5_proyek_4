import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/network_status_banner.dart';
import 'auth_controller.dart';

class UserManagementView extends StatefulWidget {
  const UserManagementView({super.key});

  @override
  State<UserManagementView> createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final AuthController _authController = AuthController.instance;

  bool _isPageLoading = true;
  List<MemberModel> _users = const [];

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _isPageLoading = true;
    });

    final users = await _authController.getAllUsers();

    if (!mounted) return;
    setState(() {
      _users = users;
      _isPageLoading = false;
    });
  }

  String _roleLabel(String role) {
    switch (role.trim().toLowerCase()) {
      case AppConstants.roleAdmin:
        return 'Admin';
      case AppConstants.roleManager:
        return 'Manager';
      case AppConstants.roleOrganizer:
        return 'Organizer';
      default:
        return 'Member';
    }
  }

  List<DropdownMenuItem<String>> _buildDbuItems() {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.black54,
    );

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_departemen__',
        child: Text('Departemen', style: headerStyle),
      ),
      ...AppConstants.departmentDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_biro__',
        child: Text('Biro', style: headerStyle),
      ),
      ...AppConstants.biroDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
      const DropdownMenuItem<String>(
        enabled: false,
        value: '__header_unit__',
        child: Text('Unit', style: headerStyle),
      ),
      ...AppConstants.unitDbuOptions.map(
        (value) => DropdownMenuItem<String>(value: value, child: Text(value)),
      ),
    ];

    return items;
  }

  Future<void> _showUserForm({MemberModel? existing}) async {
    final isEdit = existing != null;
    final formKey = GlobalKey<FormState>();

    final nimController = TextEditingController(text: existing?.nim ?? '');
    final namaController = TextEditingController(text: existing?.nama ?? '');
    final passwordController = TextEditingController();

    String selectedRole = existing?.role ?? AppConstants.roleMember;
    String selectedDbu =
        existing?.divisi ?? AppConstants.departmentDbuOptions.first;

    if (!AppConstants.allDbuOptions.contains(selectedDbu)) {
      selectedDbu = AppConstants.departmentDbuOptions.first;
    }

    bool isSaving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }

              setDialogState(() {
                isSaving = true;
              });

              final success = isEdit
                  ? await _authController.updateUserByAdmin(
                      nim: existing.nim,
                      nama: namaController.text,
                      divisi: selectedDbu,
                      role: selectedRole,
                      password: passwordController.text.trim().isEmpty
                          ? null
                          : passwordController.text,
                    )
                  : await _authController.createUserByAdmin(
                      nama: namaController.text,
                      nim: nimController.text,
                      divisi: selectedDbu,
                      role: selectedRole,
                      password: passwordController.text,
                    );

              if (!context.mounted) return;

              if (success) {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() {
                  isSaving = false;
                });
                CustomSnackbar.showError(
                  this.context,
                  _authController.errorMessage.value ??
                      'Gagal menyimpan data anggota.',
                );
              }
            }

            return AlertDialog(
              title: Text(isEdit ? 'Edit Anggota' : 'Tambah Anggota'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nimController,
                          enabled: !isEdit,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'NIM',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'NIM wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama wajib diisi.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                          ),
                          items: AppConstants.allowedRoles
                              .map(
                                (role) => DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(_roleLabel(role)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedRole = value;
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
                        DropdownButtonFormField<String>(
                          value: selectedDbu,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Departemen/Biro/Unit (DBU)',
                            prefixIcon: Icon(Icons.account_tree_outlined),
                          ),
                          items: _buildDbuItems(),
                          onChanged: (value) {
                            if (value == null ||
                                !AppConstants.allDbuOptions.contains(value)) {
                              return;
                            }
                            setDialogState(() {
                              selectedDbu = value;
                            });
                          },
                          validator: (value) {
                            if (value == null ||
                                !AppConstants.allDbuOptions.contains(value)) {
                              return 'DBU wajib dipilih.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? 'Password baru (opsional)'
                                : 'Password',
                            prefixIcon: const Icon(Icons.key_outlined),
                          ),
                          validator: (value) {
                            if (!isEdit && (value == null || value.isEmpty)) {
                              return 'Password wajib diisi.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : submit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isEdit ? 'Simpan' : 'Tambah'),
                ),
              ],
            );
          },
        );
      },
    );

    nimController.dispose();
    namaController.dispose();
    passwordController.dispose();

    if (saved == true) {
      await _refreshUsers();
      if (!mounted) return;
      CustomSnackbar.showSuccess(
        context,
        isEdit
            ? 'Data anggota berhasil diperbarui.'
            : 'Anggota baru berhasil ditambahkan.',
      );
    }
  }

  Future<void> _confirmDelete(MemberModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Hapus akun ${user.nama} (${user.nim})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _authController.deleteUserByAdmin(user.nim);
    if (!mounted) return;

    if (!success) {
      CustomSnackbar.showError(
        context,
        _authController.errorMessage.value ?? 'Gagal menghapus anggota.',
      );
      return;
    }

    await _refreshUsers();
    if (!mounted) return;

    CustomSnackbar.showSuccess(context, 'Akun berhasil dihapus.');
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) =>
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        ),
        columns: const [
          DataColumn(label: Text('No')),
          DataColumn(label: Text('NIM')),
          DataColumn(label: Text('Nama')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Departemen/Biro/Unit (DBU)')),
          DataColumn(label: Text('Action')),
        ],
        rows: List<DataRow>.generate(_users.length, (index) {
          final user = _users[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(user.nim)),
              DataCell(Text(user.nama)),
              DataCell(Text(_roleLabel(user.role))),
              DataCell(SizedBox(width: 280, child: Text(user.divisi))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showUserForm(existing: user),
                    ),
                    IconButton(
                      tooltip: 'Hapus',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _confirmDelete(user),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NetworkStatusBanner(
      child: LoadingOverlay(
        isLoading: _isPageLoading,
        message: 'Memproses data anggota...',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Manajemen Anggota'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _refreshUsers,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUserForm(),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Tambah Anggota'),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshUsers,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Admin dapat mengelola seluruh akun: Admin, Manager, Organizer, dan Member.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _users.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text('Belum ada data anggota.'),
                            ),
                          )
                        : _buildTable(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
