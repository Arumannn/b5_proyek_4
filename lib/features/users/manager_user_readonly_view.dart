import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/table_page_body.dart';

import '../auth/auth_controller.dart';
import '../../models/member_model.dart';
import 'user_permission.dart';

class ManagerUserReadonlyView extends StatefulWidget {
  const ManagerUserReadonlyView({super.key});

  @override
  State<ManagerUserReadonlyView> createState() =>
      _ManagerUserReadonlyViewState();
}

class _ManagerUserReadonlyViewState extends State<ManagerUserReadonlyView> {
  bool _isLoading = true;
  List<MemberModel> _users = const [];

  String get _currentRole =>
      (AuthController.instance.currentUser.value?.role ?? '').trim().toLowerCase();

  bool get _hasAccess => UserPermission.canViewUsers(_currentRole);

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final users = await AuthController.instance.getAllUsers();

    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  String _roleLabel(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == AppConstants.roleExecutive.toLowerCase()) return 'Executive';
    if (normalized == AppConstants.roleManager.toLowerCase()) return 'Manager';
    if (normalized == AppConstants.roleOrganizer.toLowerCase()) return 'Organizer';
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAccess) {
      return Scaffold(
        appBar: const GradientHeader(
          title: 'Data Akun Pengguna',
          subtitle: 'Akses terbatas',
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Halaman ini hanya dapat diakses oleh admin/manager.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        appBar: GradientHeader(
          title: 'Data Akun Pengguna',
          subtitle: 'Mode read-only untuk manager',
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FD),
      body: TablePageBody(
        header: GradientHeader(
          title: 'Data Akun Pengguna',
          subtitle: 'Mode read-only untuk manager',
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
        summaryArea: const Text(
          'Anda hanya dapat melihat data akun tanpa akses tambah, edit, atau hapus di halaman ini.',
        ),
        filterArea: const SizedBox.shrink(),
        tableBuilder: (context) => _users.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('Belum ada akun pengguna.'),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('NIM')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Role')),
                    DataColumn(
                      label: Text('Departemen/Biro/Unit'),
                    ),
                  ],
                  rows: _users
                      .map((u) {
                        return DataRow(
                          cells: [
                            DataCell(Text(u.nim)),
                            DataCell(Text(u.nama)),
                            DataCell(Text(_roleLabel(u.role))),
                            DataCell(Text(u.divisi)),
                          ],
                        );
                      })
                      .toList(growable: false),
                ),
              ),
        emptyState: const SizedBox.shrink(),
        onRefresh: _loadUsers,
      ),
    );
  }
}
