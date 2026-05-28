import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Controller konfigurasi yang bertindak sebagai "jembatan" antara UI dan Backend.
/// Saat ini menggunakan nilai bawaan (dummy), sementara anggota tim lain
/// akan mengembangkan logika sinkronisasi MongoDB/Hive di dalamnya.
class ConfigController extends ChangeNotifier {
  static final ConfigController instance = ConfigController._internal();
  ConfigController._internal();

  // ─── Nilai Bawaan (Dummy) ──────────────────────────────────
  // Nantinya, nilai-nilai ini akan digantikan dengan data yang diambil dari
  // OrganizationModel (MongoDB -> Hive).

  List<String> get eventTypes => [
    'Rapat',
    'Acara',
    'Kegiatan',
    'Lainnya',
  ];

  List<String> get penyelenggaraOptions => [
    'Biro Administrasi dan Kesekretariatan',
    'Biro Kewirausahaan dan Keuangan',
    'Departemen Komunikasi dan Informasi',
    'Departemen Luar Himpunan',
    'Departemen Pengembangan Sumber Daya Himpunan',
    'Departemen Seni dan Olahraga',
    'Departemen Keilmuan dan Keprofesian',
    'Unit Teknologi',
    'Badan Khusus Manajemen Sumber Daya Himpunan',
    'Himpunan',
  ];

  List<String> dbuOptionsForRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (normalized == AppConstants.roleExecutive) {
      return [
        'Ketua Himpunan',
        'Wakil Ketua Himpunan',
        'Sekretaris Jenderal',
        'Sekretaris Umum',
        'Bendahara Umum',
        'Ketua Manajemen Sumber Daya Himpunan',
      ];
    }
    if (normalized == AppConstants.roleManager) {
      return [
        'Ketua Departemen',
        'Wakil Ketua Departemen',
        'Ketua Biro',
        'Wakil Ketua Biro',
        'Ketua Unit',
        'Wakil Ketua Unit',
      ];
    }
    return [
      'Departemen Komunikasi dan Informasi',
      'Departemen Luar Himpunan',
      'Departemen Pengembangan Sumber Daya Himpunan',
      'Departemen Seni dan Olahraga',
      'Departemen Keilmuan dan Keprofesian',
      'Biro Kewirausahaan dan Keuangan',
      'Biro Administrasi dan Kesekretariatan',
      'Unit Teknologi',
    ];
  }

  String defaultDbuForRole(String role) => dbuOptionsForRole(role).first;
}
