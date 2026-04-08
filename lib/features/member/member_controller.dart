import 'package:flutter/foundation.dart';

// TODO Week 8: Implementasi penuh MemberController

/// Controller untuk manajemen data anggota.
/// Implementasi penuh: Week 8
class MemberController {
  static final MemberController instance = MemberController._internal();
  MemberController._internal();

  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  // TODO Week 8: getAllMembers(), getMemberById(), updateMember()
}