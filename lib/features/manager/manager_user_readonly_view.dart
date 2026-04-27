import 'package:flutter/material.dart';

import '../../features/auth/auth_controller.dart';
import '../../models/member_model.dart';

class ManagerUserReadonlyView extends StatefulWidget {
  const ManagerUserReadonlyView({super.key});

  @override
  State<ManagerUserReadonlyView> createState() =>
      _ManagerUserReadonlyViewState();
}

class _ManagerUserReadonlyViewState extends State<ManagerUserReadonlyView> {
  bool _isLoading = true;
  List<MemberModel> _users = const [];

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
    if (normalized == 'executive') return 'Executive';
    if (normalized == 'manager') return 'Manager';
    if (normalized == 'organizer') return 'Organizer';
    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Akun Pengguna (Read-Only)'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Manager hanya dapat melihat data akun tanpa akses tambah, edit, atau hapus.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _users.isEmpty
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
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
