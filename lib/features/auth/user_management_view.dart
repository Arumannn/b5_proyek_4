import 'package:flutter/material.dart';

import '../../widgets/gradient_header.dart';

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

    String get _currentRole =>
      (_authController.currentUser.value?.role ?? '').trim().toLowerCase();

    bool get _hasAccess =>
      _currentRole == AppConstants.roleExecutive.toLowerCase() ||
      _currentRole == 'executive' ||
      _currentRole == 'eksekutif' ||
      _currentRole == 'admin';

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
    final normalized = role.trim().toLowerCase();
    if (normalized == 'executive' || normalized == 'eksekutif' || normalized == 'admin') {
      return 'Executive';
    }
    if (normalized == AppConstants.roleManager) return 'Manager';
    if (normalized == AppConstants.roleOrganizer) return 'Organizer';
    return 'Member';
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

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UserFormDialog(
        authController: _authController,
        existing: existing,
        roleLabelBuilder: _roleLabel,
        dbuItemsBuilder: _buildDbuItems,
      ),
    );

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

    final success = await _authController.deleteUserByExecutive(user.nim);
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
    if (!_hasAccess) {
      return Scaffold(
        appBar: const GradientHeader(
          title: 'Manajemen Anggota',
          subtitle: 'Akses terbatas',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya dapat diakses oleh Executive.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return NetworkStatusBanner(
      child: LoadingOverlay(
        isLoading: _isPageLoading,
        message: 'Memproses data anggota...',
        child: Scaffold(
          appBar: GradientHeader(
            title: 'Manajemen Anggota',
            subtitle: 'Kelola akun Executive, Manager, Organizer, dan Member',
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh, color: Colors.white),
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
                  'Executive dapat mengelola seluruh akun: Executive, Manager, Organizer, dan Member.',
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
  final List<DropdownMenuItem<String>> Function() dbuItemsBuilder;

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

    final existingRole =
        (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
    _selectedRole = AppConstants.allowedRoles.firstWhere(
      (role) => role.trim().toLowerCase() == existingRole,
      orElse: () => AppConstants.roleMember,
    );
    _selectedDbu =
        widget.existing?.divisi ?? AppConstants.departmentDbuOptions.first;
    if (!AppConstants.allDbuOptions.contains(_selectedDbu)) {
      _selectedDbu = AppConstants.departmentDbuOptions.first;
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = _isEdit
        ? await widget.authController.updateUserByExecutive(
            nim: widget.existing!.nim,
            nama: _namaController.text,
            divisi: _selectedDbu,
            role: _selectedRole,
            password: _passwordController.text.trim().isEmpty
                ? null
                : _passwordController.text,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Anggota' : 'Tambah Anggota'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nimController,
                  enabled: !_isEdit,
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
                  controller: _namaController,
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
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: AppConstants.allowedRoles
                      .map(
                        (role) => DropdownMenuItem<String>(
                          value: role,
                          child: Text(widget.roleLabelBuilder(role)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedRole = value;
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
                  initialValue: _selectedDbu,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Departemen/Biro/Unit (DBU)',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  items: widget.dbuItemsBuilder(),
                  onChanged: (value) {
                    if (value == null ||
                        !AppConstants.allDbuOptions.contains(value)) {
                      return;
                    }
                    setState(() {
                      _selectedDbu = value;
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
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'Password baru (opsional)' : 'Password',
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                  validator: (value) {
                    if (!_isEdit && (value == null || value.isEmpty)) {
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
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _submit,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}
