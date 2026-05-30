import 'package:flutter/foundation.dart';

import '../../models/organization_config.dart';
import '../services/hive_service.dart';
import '../../features/auth/auth_controller.dart';

/// Controller konfigurasi yang bertindak sebagai "jembatan" antara UI dan Backend.
/// Sekarang mendukung Dynamic RBAC & Multi-Tenancy.
class ConfigController extends ChangeNotifier {
  static final ConfigController instance = ConfigController._internal();
  ConfigController._internal();

  OrganizationConfig? _activeConfig;

  /// Memuat konfigurasi aktif berdasarkan organizationId dari user yang login.
  void loadActiveConfig() {
    final user = AuthController.instance.currentUser.value;
    final orgId = user?.organizationId;

    if (orgId == null || orgId.isEmpty) {
      _activeConfig = OrganizationConfig.defaultFallback;
    } else {
      final configFromHive = HiveService.organizationConfigs.get(orgId);
      _activeConfig = configFromHive ?? OrganizationConfig.defaultFallback;
    }
    notifyListeners();
  }

  OrganizationConfig get activeConfig {
    if (_activeConfig == null) {
      loadActiveConfig();
    }
    return _activeConfig!;
  }

  List<String> get eventTypes => activeConfig.eventTypes;

  /// Mendapatkan daftar Jabatan/Departemen (DBU) yang diizinkan untuk peran/role tertentu
  List<String> dbuOptionsForRole(String systemRole) {
    final normalized = systemRole.trim().toLowerCase();
    
    // Cari role di config
    for (final roleConfig in activeConfig.rolesConfig) {
      if (roleConfig.roleName.toLowerCase() == normalized) {
        return roleConfig.allowedDivisions;
      }
    }
    
    // Fallback DBU
    return ['Belum Ditentukan'];
  }

  String defaultDbuForRole(String systemRole) {
    final options = dbuOptionsForRole(systemRole);
    if (options.isNotEmpty) return options.first;
    return 'Belum Ditentukan';
  }

  List<String> get allDbuOptions {
    final set = <String>{};
    for (final roleConfig in activeConfig.rolesConfig) {
      set.addAll(roleConfig.allowedDivisions);
    }
    return set.toList();
  }

  /// Alias for backward compatibility on some UIs if needed
  List<String> get penyelenggaraOptions => allDbuOptions;
}
