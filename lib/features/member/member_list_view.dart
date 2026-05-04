import 'package:flutter/material.dart';

import '../../core/services/hive_service.dart';
import '../../models/member_model.dart';
import '../../widgets/member_card.dart';
import 'member_profile_view.dart';

class MemberListView extends StatefulWidget {
  const MemberListView({Key? key}) : super(key: key);

  @override
  State<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView> {
  List<MemberModel> _members = const <MemberModel>[];
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
    return _members
        .where(
          (m) =>
              m.nama.toLowerCase().contains(q) ||
              m.nim.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Anggota',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total ${_members.length} anggota aktif',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Cari nama atau NIM...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadMembers(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_filtered.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemberProfileView(
                            nama: m.nama,
                            nim: m.nim,
                            divisi: m.divisi,
                          ),
                        ),
                      );
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
