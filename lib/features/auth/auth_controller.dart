import 'package:flutter/foundation.dart';

// TODO Week 8: Uncomment setelah MemberModel diimplementasi
// import '../../models/member_model.dart';
// import '../../core/services/hive_service.dart';
// import '../../core/services/mongo_service.dart';
// import '../../core/constants/app_constants.dart';

/// Controller untuk fitur autentikasi (Login, Register, Logout).
///
/// RULES (WAJIB):
/// - Tidak ada import material.dart di sini
/// - Semua state di-expose via ValueNotifier
/// - Logic login: lookup Hive dulu → fallback ke cloud jika tidak ada
/// - Logout: HARUS gunakan pushAndRemoveUntil (implemented di View)
///
/// Implementasi penuh: Week 8
class AuthController {
  // ─── Singleton ─────────────────────────────────────
  static final AuthController instance = AuthController._internal();
  AuthController._internal();

  // ─── State via ValueNotifier ───────────────────────
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  // TODO Week 8: final ValueNotifier<MemberModel?> currentUser = ValueNotifier(null);

  // ─── TODO Week 8: Implementasi Methods ────────────
  // Future<bool> register({required String nama, required String nim,
  //   required String divisi, required String role, required String password})
  //
  // Future<bool> login({required String nim, required String password})
  //
  // Future<void> logout(BuildContext context) — gunakan pushAndRemoveUntil!
  //
  // void clearSession()

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
  }
}