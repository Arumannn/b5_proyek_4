import 'package:hive/hive.dart';

part 'organization_config.g.dart';

@HiveType(typeId: 9)
class RoleConfig {
  @HiveField(0)
  final String roleName;

  @HiveField(1)
  final List<String> permissions;

  @HiveField(2)
  final List<String> allowedDivisions;

  RoleConfig({
    required this.roleName,
    required this.permissions,
    required this.allowedDivisions,
  });

  factory RoleConfig.fromMap(Map<String, dynamic> map) {
    return RoleConfig(
      roleName: map['roleName']?.toString() ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      allowedDivisions: List<String>.from(map['allowedDivisions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roleName': roleName,
      'permissions': permissions,
      'allowedDivisions': allowedDivisions,
    };
  }
}

@HiveType(typeId: 10)
class OrganizationConfig extends HiveObject {
  @HiveField(0)
  final String organizationId;

  @HiveField(1)
  final List<String> eventTypes;

  @HiveField(2)
  final List<RoleConfig> rolesConfig;

  OrganizationConfig({
    required this.organizationId,
    required this.eventTypes,
    required this.rolesConfig,
  });

  factory OrganizationConfig.fromMap(Map<String, dynamic> map) {
    final rolesList = map['rolesConfig'] as List<dynamic>? ?? [];
    return OrganizationConfig(
      organizationId: map['organizationId']?.toString() ?? '',
      eventTypes: List<String>.from(map['eventTypes'] ?? []),
      rolesConfig: rolesList.map((e) => RoleConfig.fromMap(Map<String, dynamic>.from(e))).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'eventTypes': eventTypes,
      'rolesConfig': rolesConfig.map((r) => r.toMap()).toList(),
    };
  }

  /// Default fallback configuration if cloud sync fails and no local cache exists
  static OrganizationConfig get defaultFallback {
    return OrganizationConfig(
      organizationId: 'DEFAULT',
      eventTypes: ['Rapat', 'Acara', 'Kegiatan', 'Lainnya'],
      rolesConfig: [
        RoleConfig(
          roleName: 'Executive',
          permissions: [
            'create_main_event',
            'update_main_event',
            'delete_main_event',
            'create_sub_event',
            'update_sub_event',
            'delete_sub_event',
          ],
          allowedDivisions: [
            'Ketua Himpunan',
            'Wakil Ketua Himpunan',
            'Sekretaris Jenderal',
            'Sekretaris Umum',
            'Bendahara Umum',
            'Ketua Manajemen Sumber Daya Himpunan',
          ],
        ),
        RoleConfig(
          roleName: 'Manager',
          permissions: [
            'create_sub_event',
            'update_sub_event',
            'delete_sub_event',
          ],
          allowedDivisions: [
            'Ketua Departemen',
            'Wakil Ketua Departemen',
            'Ketua Biro',
            'Wakil Ketua Biro',
            'Ketua Unit',
            'Wakil Ketua Unit',
          ],
        ),
        RoleConfig(
          roleName: 'Member',
          permissions: [],
          allowedDivisions: [
            'Departemen Komunikasi dan Informasi',
            'Departemen Luar Himpunan',
            'Departemen Pengembangan Sumber Daya Himpunan',
            'Departemen Seni dan Olahraga',
            'Departemen Keilmuan dan Keprofesian',
            'Biro Kewirausahaan dan Keuangan',
            'Biro Administrasi dan Kesekretariatan',
            'Unit Teknologi',
          ],
        ),
      ],
    );
  }
}
