import 'package:hive/hive.dart';

part 'organization_config.g.dart';

@HiveType(typeId: 9)
class RoleConfig {
  @HiveField(0)
  final String roleName;

  @HiveField(1)
  final List<String> permissions;

  @HiveField(2)
  final List<String> jabatanList;

  RoleConfig({
    required this.roleName,
    required this.permissions,
    required this.jabatanList,
  });

  factory RoleConfig.fromMap(Map<String, dynamic> map) {
    final rawJabatan = map['jabatanList'] ?? map['jabatan'] ?? map['divisi'] ?? [];
    final jabatan = rawJabatan is List
        ? rawJabatan.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList()
        : <String>[];

    return RoleConfig(
      roleName: map['roleName']?.toString() ?? map['name']?.toString() ?? '',
      permissions: List<String>.from(map['permissions'] ?? []),
      jabatanList: jabatan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roleName': roleName,
      'permissions': permissions,
      'jabatanList': jabatanList,
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
            'read_dashboard',
            'create_event', 'read_event', 'update_event', 'delete_event',
            'create_sub_event', 'read_sub_event', 'update_sub_event', 'delete_sub_event',
            'create_member', 'read_member', 'update_member', 'delete_member',
            'read_kehadiran',
            'create_scan',
            'read_rekap',
          ],
          jabatanList: [
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
            'read_dashboard',
            'read_event',
            'create_sub_event', 'read_sub_event', 'update_sub_event', 'delete_sub_event',
            'read_member',
            'read_kehadiran',
            'create_scan',
            'read_rekap',
          ],
          jabatanList: [
            'Ketua Departemen',
            'Wakil Ketua Departemen',
            'Ketua Biro',
            'Wakil Ketua Biro',
            'Ketua Unit',
            'Wakil Ketua Unit',
          ],
        ),
        RoleConfig(
          roleName: 'Organizer',
          permissions: [
            'read_dashboard',
            'read_event',
            'read_sub_event',
            'read_kehadiran',
            'read_rekap',
          ],
          jabatanList: [
            'Koordinator Acara', 
            'Koordinator Logistik', 
            'Koordinator Publikasi'
          ],
        ),
        RoleConfig(
          roleName: 'Member',
          permissions: [
            'read_dashboard',
            'read_event',
            'read_sub_event',
            'read_kehadiran',
            'read_rekap',
          ],
          jabatanList: [
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
