import 'package:flutter/foundation.dart';
import '../../core/services/hive_service.dart';
import '../../models/member_model.dart';

class MemberController {
  static final MemberController instance = MemberController._internal();
  MemberController._internal();

  // State Management
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<List<MemberModel>> members = ValueNotifier([]);
  final ValueNotifier<List<MemberModel>> filteredMembers = ValueNotifier([]);
  
  // Filter & Search State
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<String> selectedDivision = ValueNotifier('Semua');
  final ValueNotifier<List<String>> availableDivisions = ValueNotifier(['Semua']);

  void loadMembers() {
    isLoading.value = true;
    try {
      final all = HiveService.members.values.toList();
      members.value = all;

      // Extract divisi unik dari data yang ada di Hive
      final divs = all.map((m) => m.divisi).where((d) => d.isNotEmpty).toSet().toList();
      divs.sort();
      availableDivisions.value = ['Semua', ...divs];

      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void setDivision(String division) {
    selectedDivision.value = division;
    _applyFilters();
  }

  void _applyFilters() {
    List<MemberModel> result = members.value;

    // Filter by Division
    if (selectedDivision.value != 'Semua') {
      result = result.where((m) => m.divisi == selectedDivision.value).toList();
    }

    // Filter by Search Query
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((m) =>
          m.nama.toLowerCase().contains(q) ||
          m.nim.toLowerCase().contains(q)).toList();
    }

    filteredMembers.value = result;
  }

  // Helper untuk menampilkan jumlah angka di dalam Chips
  int getDivisionCount(String division) {
    if (division == 'Semua') return members.value.length;
    return members.value.where((m) => m.divisi == division).length;
  }
}