import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/network_status_banner.dart';
import '../../widgets/table_page_body.dart';
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

  String get _currentRole => (_authController.currentUser.value?.role ?? '').trim().toLowerCase();

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
    if (mounted) {
      setState(() {
        _isPageLoading = true;
      });
    }

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

    return [
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
        isEdit ? 'Data anggota berhasil diperbarui.' : 'Anggota baru berhasil ditambahkan.',
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

    if (confirmed != true) return;

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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Manajemen Anggota',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.manage_accounts_outlined, size: 44, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_users.length} akun anggota',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelola Executive, Manager, Organizer, dan Member dari satu layar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryTile(
              label: 'Total Akun',
              value: '${_users.length}',
              icon: Icons.groups_2_outlined,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _summaryTile(
              label: 'Akses',
              value: _hasAccess ? 'Admin' : 'Terbatas',
              icon: Icons.verified_user_outlined,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.resolveWith(
          (states) => Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
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
        backgroundColor: const Color(0xFFF3F7FD),
        body: SafeArea(
          child: Column(
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
                ),
                child: const Text(
                  'Manajemen Anggota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Halaman ini hanya dapat diakses oleh Executive.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return NetworkStatusBanner(
      child: LoadingOverlay(
        isLoading: _isPageLoading,
        message: 'Memproses data anggota...',
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F7FD),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showUserForm(),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Tambah Anggota'),
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          body: TablePageBody(
            header: _buildHeader(),
            summaryArea: _buildSummaryCard(),
            filterArea: const SizedBox.shrink(),
            tableBuilder: (context) => _users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Belum ada data anggota.'),
                    ),
                  )
                : _buildTable(),
            emptyState: const SizedBox.shrink(),
            onRefresh: _refreshUsers,
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

    final existingRole = (widget.existing?.role ?? AppConstants.roleMember).trim().toLowerCase();
    _selectedRole = AppConstants.allowedRoles.firstWhere(
      (role) => role.trim().toLowerCase() == existingRole,
      orElse: () => AppConstants.roleMember,
    );
    _selectedDbu = widget.existing?.divisi ?? AppConstants.departmentDbuOptions.first;
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
            password: _passwordController.text.trim().isEmpty ? null : _passwordController.text,
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
                        _buildFieldLabel('Role'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          isExpanded: true,
                          decoration: _inputDecoration(),
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
                        _buildFieldLabel('Departemen/Biro/Unit (DBU)'),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDbu,
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: widget.dbuItemsBuilder(),
                          onChanged: (value) {
                            if (value == null || !AppConstants.allDbuOptions.contains(value)) {
                              return;
                            }
                            setState(() {
                              _selectedDbu = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || !AppConstants.allDbuOptions.contains(value)) {
                              return 'DBU wajib dipilih.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFieldLabel(_isEdit ? 'Password Baru (Opsional)' : 'Password'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(hintText: 'Masukkan password'),
                          validator: (value) {
                            if (!_isEdit && (value == null || value.isEmpty)) {
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