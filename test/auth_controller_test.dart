import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:b5_proyek_4/core/constants/app_constants.dart';
import 'package:b5_proyek_4/core/services/hive_service.dart';
import 'package:b5_proyek_4/features/auth/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  final auth = AuthController.instance;

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return Directory.systemTemp.path;
    });

    await HiveService.init();
    await auth.initializeAuth(); // seed default accounts
  });

  tearDownAll(() async {
    await HiveService.closeAll();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  setUp(() {
    auth.clearSession();
    auth.errorMessage.value = null;
  });

  group('AuthController — Week 8 Unit Tests', () {
    // TC-01: Login NIM + password benar → currentUser tidak null, role sesuai
    test('TC-01: Login Executive valid → currentUser tidak null, role = Executive',
        () async {
      final ok = await auth.verifyCredentials(
        nim: AppConstants.defaultExecutiveNim,
        password: AppConstants.defaultExecutivePassword,
      );
      expect(ok, isTrue, reason: 'Login harus berhasil dengan kredensial benar');
      expect(auth.currentUser.value, isNotNull);
      expect(auth.currentUser.value!.role, equals(AppConstants.roleExecutive));
      expect(auth.errorMessage.value, isNull);
    });

    // TC-02: Executive buat akun member baru → tersimpan di Hive, role benar
    test('TC-02: Executive createUserByExecutive → tersimpan di Hive dengan role member',
        () async {
      // Login sebagai Executive dulu
      await auth.verifyCredentials(
        nim: AppConstants.defaultExecutiveNim,
        password: AppConstants.defaultExecutivePassword,
      );

      const testNim = '999000099';
      final ok = await auth.createUserByExecutive(
        nama: 'Test Member Baru',
        nim: testNim,
        divisi: 'Test Divisi',
        role: AppConstants.roleMember,
        password: 'test123',
      );

      expect(ok, isTrue, reason: 'Executive harus bisa buat akun member baru');

      final saved = HiveService.members.get(testNim);
      expect(saved, isNotNull, reason: 'Member harus tersimpan di Hive');
      expect(saved!.role, equals(AppConstants.roleMember));
      expect(saved.nim, equals(testNim));

      // Cleanup
      await HiveService.members.delete(testNim);
    });

    // TC-03: Login password salah → gagal, error message muncul
    test('TC-03: Login password salah → gagal + error message tidak null',
        () async {
      final ok = await auth.verifyCredentials(
        nim: AppConstants.defaultExecutiveNim,
        password: 'passwordsalah_ini_pasti_gagal',
      );
      expect(ok, isFalse, reason: 'Login harus gagal dengan password salah');
      expect(auth.currentUser.value, isNull);
      expect(auth.errorMessage.value, isNotNull);
      expect(auth.errorMessage.value!.isNotEmpty, isTrue);
    });

    // TC-04: Login NIM tidak terdaftar → gagal, tidak crash
    test('TC-04: Login NIM tidak terdaftar → gagal tanpa crash', () async {
      final ok = await auth.verifyCredentials(
        nim: '000000000_tidak_ada',
        password: 'apapun',
      );
      expect(ok, isFalse, reason: 'Login harus gagal untuk NIM tidak dikenal');
      expect(auth.currentUser.value, isNull);
      expect(auth.errorMessage.value, isNotNull);
    });
  });
}