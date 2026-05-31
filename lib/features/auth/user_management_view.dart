// ignore_for_file: unused_element

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/controllers/config_controller.dart';

import '../../models/member_model.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/network_status_banner.dart';
import '../../widgets/table_page_body.dart';
import '../../widgets/custom_confirm_dialog.dart';
import 'auth_controller.dart';
import 'widgets/user_form_dialog.dart';

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

  String get _currentRole => (_authController.currentUser.value?.role ?? '').trim().toLowerCase();

  bool get _hasAccess =>
      _currentRole == AppConstants.roleExecutive.toLowerCase();

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
    if (normalized == AppConstants.roleExecutive) return 'Executive';
    if (normalized == AppConstants.roleManager) return 'Manager';
    if (normalized == AppConstants.roleOrganizer) return 'Organizer';
    return 'Member';
  }

  List<String> _buildDbuItems(String role) {
    return ConfigController.instance.dbuOptionsForRole(role);
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
        return CustomConfirmDialog(
          title: 'Konfirmasi Hapus',
          content: 'Hapus akun ${user.nama} (${user.nim})?',
          confirmText: 'Hapus',
          isDestructive: true,
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
                    const SizedBox(width: 8),
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
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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

