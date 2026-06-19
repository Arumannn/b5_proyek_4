import 'package:flutter/foundation.dart';

import 'package:b5_proyek_4/domain/constants/app_constants.dart';
import 'package:b5_proyek_4/domain/models/setup/organization_config.dart';
import 'package:b5_proyek_4/data/services/hive_service.dart';
import 'package:b5_proyek_4/domain/controllers/auth/auth_controller.dart';

/// Controller konfigurasi yang bertindak sebagai "jembatan" antara UI dan Backend.
/// Sekarang mendukung Dynamic RBAC & Multi-Tenancy.
class ConfigController extends ChangeNotifier {
  static final ConfigController instance = ConfigController._internal();
  ConfigController._internal();

  static const List<String> _defaultEventTypes = ['Rapat', 'Acara', 'Kegiatan', 'Lainnya'];
  static const List<String> _defaultDbuOptions = ['Belum Ditentukan'];

  OrganizationConfig? _activeConfig;

  /// Memuat konfigurasi aktif berdasarkan organizationId dari user yang login.
  void loadActiveConfig() {
    final user = AuthController.instance.currentUser.value;
    final orgId = user?.organizationId;

    if (orgId == null || orgId.isEmpty) {
      _activeConfig =
          HiveService.organizationConfigs.get(OrganizationConfig.defaultFallback.organizationId) ??
          OrganizationConfig.defaultFallback;
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

  List<String> get eventTypes {
    final types = activeConfig.eventTypes;
    return types.isNotEmpty ? types : _defaultEventTypes;
  }

  /// Mendapatkan daftar Jabatan/Departemen (DBU) yang diizinkan untuk peran/role tertentu
  List<String> dbuOptionsForRole(String systemRole) {
    for (final roleConfig in activeConfig.rolesConfig) {
      if (roleMatchesConfiguredName(systemRole, roleConfig.roleName)) {
        return roleConfig.jabatanList.isNotEmpty ? roleConfig.jabatanList : _defaultDbuOptions;
      }
    }
    
    // Fallback DBU
    return _defaultDbuOptions;
  }

  String defaultDbuForRole(String systemRole) {
    final options = dbuOptionsForRole(systemRole);
    if (options.isNotEmpty) return options.first;
    return _defaultDbuOptions.first;
  }

  List<String> get allDbuOptions {
    final set = <String>{};
    for (final roleConfig in activeConfig.rolesConfig) {
      set.addAll(roleConfig.jabatanList);
    }
    return set.isNotEmpty ? set.toList() : _defaultDbuOptions;
  }

  bool roleMatchesConfiguredName(String roleOrJobTitle, String configuredRoleName) {
    final normalizedRole = roleOrJobTitle.trim().toLowerCase();
    final normalizedConfigured = configuredRoleName.trim().toLowerCase();

    if (normalizedRole == normalizedConfigured) {
      return true;
    }

    final aliases = <String, Set<String>>{
      AppConstants.roleExecutive.toLowerCase(): {'executive', 'eksekutif'},
      AppConstants.roleManager.toLowerCase(): {'manager'},
      AppConstants.roleOrganizer.toLowerCase(): {'organizer', 'organiser'},
      AppConstants.roleMember.toLowerCase(): {'member', 'anggota'},
    };

    // Check both directions: whether the user's role maps to the configured name
    // or vice-versa. This handles cases like 'Eksekutif' (from web-admin)
    // matching internal 'executive' and keeps matching robust for aliases.
    final roleCandidates = aliases[normalizedRole];
    if (roleCandidates != null && roleCandidates.contains(normalizedConfigured)) {
      return true;
    }

    final configuredCandidates = aliases[normalizedConfigured];
    if (configuredCandidates != null && configuredCandidates.contains(normalizedRole)) {
      return true;
    }

    // As a final check, see if both values appear in the same alias set.
    for (final set in aliases.values) {
      if (set.contains(normalizedRole) && set.contains(normalizedConfigured)) {
        return true;
      }
    }

    return false;
  }

  /// Checks whether a provided role or job title matches a given RoleConfig.
  /// This considers configured role names, known aliases, and the role's
  /// `jabatanList` (job titles) so that both role and job-title strings
  /// coming from users or older data formats will match correctly.
  bool roleOrJobMatchesConfigured(String roleOrJobTitle, RoleConfig roleConfig) {
    final normalized = roleOrJobTitle.trim().toLowerCase();
    if (roleMatchesConfiguredName(normalized, roleConfig.roleName)) return true;
    for (final jab in roleConfig.jabatanList) {
      if (jab.trim().toLowerCase() == normalized) return true;
    }
    return false;
  }

  /// Checks whether a provided role or job title matches a configured role
  /// identified by name. This is a convenience wrapper that finds the
  /// corresponding RoleConfig and delegates to [roleOrJobMatchesConfigured].
  bool roleMatchesConfiguredNameOrJob(String roleOrJobTitle, String configuredRoleName) {
    final normalizedConfigured = configuredRoleName.trim().toLowerCase();
    for (final roleConfig in activeConfig.rolesConfig) {
      if (roleConfig.roleName.trim().toLowerCase() == normalizedConfigured) {
        if (roleOrJobMatchesConfigured(roleOrJobTitle, roleConfig)) return true;
      }
    }
    return false;
  }

  /// Alias for backward compatibility on some UIs if needed
  List<String> get penyelenggaraOptions => allDbuOptions;

  /// Permission alias map to translate web-admin permission keys to
  /// the app's canonical permission keys. This helps when the admin
  /// uses slightly different naming (e.g. `read_events` vs `read_event`).
  static final Map<String, Set<String>> _permissionAliases = {
    'read_event': {'read_event', 'read_events', 'event'},
    'create_event': {'create_event', 'create_events', 'write_events', 'write_event'},
    'update_event': {'update_event', 'edit_event', 'edit_events'},
    'delete_event': {'delete_event', 'delete_events', 'remove_event'},
    'read_member': {'read_member', 'read_members', 'read_users', 'manage_users', 'member'},
    'create_member': {'create_member', 'create_users', 'add_user'},
    'update_member': {'update_member', 'edit_user', 'edit_users'},
    'delete_member': {'delete_member', 'delete_user'},
    'read_rekap': {'read_rekap', 'view_recap', 'rekap'},
    'create_scan': {'create_scan', 'read_scan', 'scan_qr', 'scan'},
    'read_dashboard': {'read_dashboard', 'view_dashboard', 'read_home', 'dashboard'},
    'read_kehadiran': {'read_kehadiran', 'read_attendance', 'view_attendance', 'kehadiran'},
  };

  /// Returns true if the provided permission list contains the required
  /// permission key or any of its known aliases.
  bool permissionListHas(List<String> permissionsList, String requiredKey) {
    final lowered = permissionsList.map((e) => e.trim().toLowerCase()).toSet();
    final normalized = requiredKey.trim().toLowerCase();
    final candidates = _permissionAliases[normalized] ?? {normalized};
    for (final c in candidates) {
      if (lowered.contains(c)) return true;
    }
    return false;
  }
}
