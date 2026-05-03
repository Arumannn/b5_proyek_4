import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/member_model.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/member_card.dart';
import 'member_profile_view.dart';

class MembersListView extends StatefulWidget {
  const MembersListView({Key? key}) : super(key: key);

  @override
  State<MembersListView> createState() => _MembersListViewState();
}

class _MembersListViewState extends State<MembersListView> {
  List<MemberModel> _members = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    final all = HiveService.members.values.toList(growable: false);
    setState(() => _members = all);
  }

  List<MemberModel> get _filtered {
    if (_query.trim().isEmpty) return _members;
    final q = _query.toLowerCase();
    return _members.where((m) => m.nama.toLowerCase().contains(q) || m.nim.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientHeader(title: 'Daftar Anggota'),
      body: RefreshIndicator(
        onRefresh: () async => _loadMembers(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '🔍 Cari nama atau NIM...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            if (_filtered.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Tidak ada anggota yang cocok.'),
                ),
              )
            else
              ..._filtered.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MemberCard(
                    name: m.nama,
                    nim: m.nim,
                    division: m.divisi,
                    attendancePercent: 0.0,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => MemberProfileView(
                        nama: m.nama,
                        nim: m.nim,
                        divisi: m.divisi,
                      )));
                    },
                  ),
                );
              }).toList(growable: false),
          ],
        ),
      ),
    );
  }
}
