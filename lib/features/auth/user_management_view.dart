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
  final TextEditingController _searchController = TextEditingController();

  bool _isPageLoading = true;
  String _selectedRoleFilter = 'Semua';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Color _roleColor(String role) {
    switch (role.trim().toLowerCase()) {
      case AppConstants.roleExecutive:
        return const Color(0xFF1E56E5);
      case AppConstants.roleManager:
        return const Color(0xFF06C755);
      case AppConstants.roleOrganizer:
        return const Color(0xFFB84DFF);
      default:
        return const Color(0xFFFD9800);
    }
  }

  List<MemberModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return _users
        .where((user) {
          final matchesQuery =
              query.isEmpty ||
              user.nama.toLowerCase().contains(query) ||
              user.nim.toLowerCase().contains(query) ||
              user.divisi.toLowerCase().contains(query);
          final matchesRole =
              _selectedRoleFilter == 'Semua' ||
              _roleLabel(user.role) == _selectedRoleFilter;
          return matchesQuery && matchesRole;
        })
        .toList(growable: false);
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

  Widget _buildUserCard(MemberModel user) {
    final role = _roleLabel(user.role);
    final color = _roleColor(user.role);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                user.nama.isNotEmpty ? user.nama[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.nama,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIM: ${user.nim}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_tree_outlined,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user.divisi,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${user.nama.toLowerCase().replaceAll(' ', '.')}@email.com',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showUserForm(existing: user),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => _confirmDelete(user),
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.red,
                            backgroundColor: const Color(0xFFFFF1F2),
                          ),
                          child: const Text('Hapus'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterChips() {
    final roles = <String>[
      'Semua',
      'Executive',
      'Manager',
      'Organizer',
      'Member',
    ];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: roles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final role = roles[index];
          final selected = _selectedRoleFilter == role;
          return ChoiceChip(
            label: Text(role),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedRoleFilter = role;
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;

    return NetworkStatusBanner(
      child: LoadingOverlay(
        isLoading: _isPageLoading,
        message: 'Memproses data anggota...',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Daftar Anggota'),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Cari nama atau NIM...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildRoleFilterChips(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Belum ada data anggota.')),
                  )
                else
                  ...users.map(_buildUserCard),
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

  bool _isExecutiveRole(String role) {
    final normalized = role.trim().toLowerCase();
    return normalized == AppConstants.roleExecutive.toLowerCase() ||
        normalized == 'executive' ||
        normalized == 'eksekutif' ||
        normalized == 'admin';
  }

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
