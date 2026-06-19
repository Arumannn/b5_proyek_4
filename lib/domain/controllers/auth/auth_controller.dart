import 'dart:async';
import 'package:flutter/material.dart';

import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/controllers/config_controller.dart';
import 'package:b5_proyek_4/data/services/fcm_service.dart';
import 'package:b5_proyek_4/data/services/sync_manager.dart';
import 'package:b5_proyek_4/domain/controllers/network_status_controller.dart';
import 'package:b5_proyek_4/domain/models/users/member_model.dart';
import 'package:b5_proyek_4/presentation/views/dashboard/main_layout.dart';
import 'package:b5_proyek_4/presentation/views/auth/login_view.dart';

import 'package:b5_proyek_4/data/datasources/local/auth/auth_local_data_source.dart';
import 'package:b5_proyek_4/data/datasources/remote/auth/auth_remote_data_source.dart';
import 'package:b5_proyek_4/data/repositories/auth/auth_repository.dart';

class AuthController {
  static final AuthController instance = AuthController._internal();
  
  late final AuthRepository _repository;
  late final VoidCallback _onlineListener;

  AuthController._internal() {
    _repository = AuthRepository(AuthLocalDataSource(), AuthRemoteDataSource());
    _onlineListener = () {
      if (NetworkStatusController.instance.isOnline.value) {
        unawaited(_repository.syncPendingUserChanges());
      }
    };
    NetworkStatusController.instance.isOnline.addListener(_onlineListener);
  }

  final ValueNotifier<MemberModel?> currentUser = ValueNotifier(null);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  Future<void> initializeAuth() async {
    await _repository.normalizeStoredRoles();
    await _repository.seedDefaultAccount();
    unawaited(_repository.syncPendingUserChanges());
  }

  Future<bool> createUserByExecutive({
    required String nama,
    required String nim,
    required String divisi,
    required String role,
    required String password,
    String? jobTitle,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat membuat akun.';
        return false;
      }
      
      if (nim.trim().isEmpty || nama.trim().isEmpty || divisi.trim().isEmpty || password.isEmpty) {
        errorMessage.value = 'NIM, Nama, Role, DBU, dan Password wajib diisi.';
        return false;
      }

      await _repository.createUser(
        nama: nama,
        nim: nim,
        divisi: divisi,
        role: role,
        password: password,
        jobTitle: jobTitle,
      );
      
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUserByExecutive({
    required String nim,
    String? nama,
    String? divisi,
    String? role,
    String? password,
    String? jobTitle,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat mengubah akun.';
        return false;
      }

      final updatedUser = await _repository.updateUser(
        nim: nim,
        nama: nama,
        divisi: divisi,
        role: role,
        password: password,
        jobTitle: jobTitle,
      );

      if (currentUser.value?.nim == nim.trim()) {
        currentUser.value = updatedUser;
      }
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteUserByExecutive(String nim) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (!_isCurrentUserExecutive()) {
        errorMessage.value = 'Hanya Executive yang dapat menghapus akun.';
        return false;
      }

      await _repository.deleteUser(nim);

      if (currentUser.value?.nim == nim.trim()) {
        clearSession();
      }

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<MemberModel>> getAllUsers() async {
    return _repository.getAllUsers();
  }

  Future<bool> login({
    required BuildContext context,
    required String nim,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _repository.seedDefaultAccount();
      
      final loggedUser = await _repository.login(nim, password);
      currentUser.value = loggedUser;
      
      try {
        final active = ConfigController.instance.activeConfig;
        for (final rc in active.rolesConfig) {
          debugPrint('[Auth][login] roleConfig: ${rc.roleName} -> permissions=${rc.permissions} jabatan=${rc.jabatanList}');
        }
      } catch (e) {
        debugPrint('[Auth][login] unable to dump activeConfig: $e');
      }

      try {
        await SyncManager.instance.pullOrganizationConfigFromCloud();
      } catch (e) {
        debugPrint('[Auth][login] config refresh warning: $e');
      }
      ConfigController.instance.loadActiveConfig();

      unawaited(_updateFcmTokenInBackground(loggedUser?.nim ?? ''));

      if (!context.mounted) return false;
      _navigateByRole(context, currentUser.value?.role ?? '');
      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout(BuildContext context) async {
    debugPrint('[Auth][logout] clearing session');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginView()),
      (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      clearSession();
    });
  }

  void clearSession() {
    currentUser.value = null;
    errorMessage.value = null;
  }
  
  Future<void> _updateFcmTokenInBackground(String nim) async {
    try {
      final token = await FcmService.instance.getFcmToken();
      if (token == null) return;
      await _repository.updateFcmTokenInBackground(nim, token);
    } catch (e) {
      debugPrint('[Auth][fcm] update failed: $e');
    }
  }

  bool _isCurrentUserExecutive() {
    final role = (currentUser.value?.role ?? '').trim().toLowerCase();
    return role == AppConstants.roleExecutive.toLowerCase();
  }

  Future<bool> verifyCredentials({
    required String nim,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final user = _repository.verifyCredentialsLocal(nim, password);
      if (user != null) {
          currentUser.value = user;
          return true;
      }
      return false;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateByRole(BuildContext context, String role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const MainLayout()),
      (route) => false,
    );
  }

  void dispose() {
    NetworkStatusController.instance.isOnline.removeListener(_onlineListener);
    currentUser.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
