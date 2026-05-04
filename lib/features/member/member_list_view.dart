import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/mongo_service.dart';
import '../../core/utils/network_status_controller.dart';
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
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Semua',
    'Humas',
    'Acara',
    'Keilmuan',
    'Medinfo',
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers({bool syncFromCloud = true}) async {
    final all = HiveService.members.values.toList(growable: false);
    if (mounted) {
      setState(() => _members = all);
    }

    if (!syncFromCloud) return;
    if (!NetworkStatusController.instance.isOnline.value) return;

    try {
      final docs = await MongoService.instance.findMany(
        collectionName: AppConstants.usersCollection,
      );

      if (docs.isEmpty) return;

      var updated = false;
      for (final raw in docs) {
        final map = Map<String, dynamic>.from(raw)..remove('_id');
        final member = MemberModel.fromMap(map);
        if (member.nim.isEmpty) continue;
        await HiveService.members.put(member.nim, member);
        updated = true;
      }

      if (updated && mounted) {
        final merged = HiveService.members.values.toList(growable: false);
        setState(() => _members = merged);
      }
    } catch (e) {
      debugPrint('[MemberList] Cloud sync skipped: $e');
    }
  }

  List<MemberModel> get _filtered {
    final q = _query.trim().toLowerCase();
    final selectedLabel = _filters[_selectedFilterIndex].toLowerCase();

    return _members.where((m) {
      final matchesQuery =
          q.isEmpty ||
          m.nama.toLowerCase().contains(q) ||
          m.nim.toLowerCase().contains(q);
      final matchesFilter =
          selectedLabel == 'semua' ||
          m.divisi.toLowerCase() == selectedLabel;
      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }

  // Fungsi bantuan untuk membuat tombol filter (Chip)
  Widget _buildFilterChip(String label, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), // Jarak antar tombol
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilterIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey[200], // Biru jika aktif, abu-abu jika tidak
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.blueGrey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: List.generate(
                  _filters.length,
                  (index) => _buildFilterChip(_filters[index], index),
                ),
              ),
            ),
          ),
            // --- TAHAP 3: DAFTAR KARTU ANGGOTA ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final member = _filtered[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MemberCard(
                    name: member.nama,
                    nim: member.nim,
                    division: member.divisi,
                    attendancePercent: 0.0,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberProfileView(
                            nama: member.nama,
                            nim: member.nim,
                            divisi: member.divisi,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ]
      )
    );
  }
}
