import 'package:flutter/material.dart';
import 'member_controller.dart';
import '../../models/member_model.dart';
// import 'member_profile_view.dart'; // Uncomment jika sudah ada

class MemberListView extends StatefulWidget {
  final bool showBottomNav;

  const MemberListView({super.key, this.showBottomNav = true});

  @override
  State<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends State<MemberListView> {
  final MemberController _controller = MemberController.instance;

  @override
  void initState() {
    super.initState();
    _controller.loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Latar abu-abu terang sesuai sketsa
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildMemberList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1D4ED8), // Biru khas PRASASTI
      elevation: 0,
      title: ValueListenableBuilder<List<MemberModel>>(
        valueListenable: _controller.members,
        builder: (context, membersList, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daftar Anggota',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
              Text(
                'Total ${membersList.length} anggota aktif',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          );
        },
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF3B66E0), // Lighter blue untuk search bar
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              style: const TextStyle(color: Color.fromARGB(0, 107, 107, 107)),
              onChanged: _controller.setSearchQuery,
              decoration: const InputDecoration(
                hintText: 'Cari nama atau NIM...',
                hintStyle: TextStyle(color: Color.fromARGB(179, 41, 41, 41)),
                prefixIcon: Icon(Icons.search, color: Color.fromARGB(179, 41, 41, 41)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      height: 60,
      child: ValueListenableBuilder<List<String>>(
        valueListenable: _controller.availableDivisions,
        builder: (context, divisions, child) {
          return ValueListenableBuilder<String>(
            valueListenable: _controller.selectedDivision,
            builder: (context, selectedDiv, child) {
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: divisions.length,
                itemBuilder: (context, index) {
                  final div = divisions[index];
                  final isSelected = div == selectedDiv;
                  final count = _controller.getDivisionCount(div);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$div ($count)'),
                      selected: isSelected,
                      onSelected: (_) => _controller.setDivision(div),
                      selectedColor: const Color(0xFF1D4ED8),
                      backgroundColor: const Color(0xFFF0F2F5),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMemberList() {
    return ValueListenableBuilder<List<MemberModel>>(
      valueListenable: _controller.filteredMembers,
      builder: (context, filtered, child) {
        if (filtered.isEmpty) {
          return const Center(
            child: Text('Tidak ada anggota yang cocok', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final member = filtered[index];
            return _MemberCardDesign(member: member);
          },
        );
      },
    );
  }
}

/// Widget Card Internal Sesuai Sketsa Desain
class _MemberCardDesign extends StatelessWidget {
  final MemberModel member;

  const _MemberCardDesign({required this.member});

  @override
  Widget build(BuildContext context) {
    // GENERATE DUMMY DATA (Sesuai Sketsa)
    final firstName = member.nama.split(' ').first.toLowerCase();
    final dummyEmail = '$firstName@email.com';
    final dummyPhone = '081234567890'; // Dummy
    
    // Asumsi random persentase kehadiran berdasarkan panjang nama (hanya untuk visual)
    final attendancePercent = 75 + (member.nama.length % 25); 
    final isHighAttendance = attendancePercent >= 90;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Bulat
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1D4ED8),
                  child: Text(
                    member.nama.isNotEmpty ? member.nama[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info Profil
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              member.nama,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Ikon Pita Kuning jika presentase kehadiran paling baik
                          if (isHighAttendance)
                            const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('NIM: ${member.nim}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 12),
                      
                      // List Info Kecil dengan Ikon
                      _buildInfoRow(Icons.person_outline, '${member.divisi} - ${member.role}'),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.mail_outline, dummyEmail),
                      const SizedBox(height: 4),
                      _buildInfoRow(Icons.phone_outlined, dummyPhone),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            
            // Progres Bar Kehadiran
            Row(
              children: [
                const Text('Tingkat Kehadiran: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: attendancePercent / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      // Hijau jika >= 90%, Biru jika di bawahnya (sesuai sketsa)
                      color: isHighAttendance ? Colors.green : const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$attendancePercent%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}