import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../models/member_model.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../models/permission_record.dart';
import '../../models/event_invitation.dart';
import '../../models/notulensi_model.dart';

class HiveService {
  HiveService._();

  static bool _initialized = false;
  static const String invitationBoxName = 'invitations';
  static const int _schemaVersion = 3;
  static const String _schemaVersionKey = '__hive_schema_version__';


  static Future<void> init() async {
    if (_initialized) {
      debugPrint(
        '⚠️ HiveService.init() dipanggil lebih dari sekali — diabaikan.',
      );
      return;
    }

    await Hive.initFlutter();

    Hive.registerAdapter(MemberModelAdapter()); // typeId: 0
    Hive.registerAdapter(EventModelAdapter()); // typeId: 1
    Hive.registerAdapter(AttendanceRecordAdapter()); // typeId: 2
    Hive.registerAdapter(PermissionRecordAdapter()); // typeId: 3
    Hive.registerAdapter(EventInvitationAdapter());
    Hive.registerAdapter(NotulensiModelAdapter());

    await _clearBoxesIfSchemaChanged();


    await _openBoxSafely<MemberModel>(AppConstants.memberBox);
    await _openBoxSafely<EventModel>(AppConstants.eventBox);
    await _openBoxSafely<AttendanceRecord>(AppConstants.attendanceBox);
    await _openBoxSafely<PermissionRecord>(AppConstants.permissionBox);
    await _openBoxSafely<EventInvitation>(invitationBoxName);
    await _openBoxSafely<String>(AppConstants.pendingUserUpsertBox);
    await _openBoxSafely<String>(AppConstants.pendingUserDeleteBox);
    await _openBoxSafely<NotulensiModel>(AppConstants.notulensiBox);

    _initialized = true;
    debugPrint('✅ HiveService initialized — 4 boxes open');
  }

  static Future<void> _clearBoxesIfSchemaChanged() async {
    // Pakai box settings untuk menyimpan versi schema
    final settingsBox = await Hive.openBox<int>('__settings__');
    final storedVersion = settingsBox.get(_schemaVersionKey) ?? 0;

    if (storedVersion < _schemaVersion) {
      debugPrint(
        '⚠️ HiveService: schema berubah '
        '(v$storedVersion → v$_schemaVersion). '
        'Membersihkan semua box...',
      );

      // Hapus semua box lama
      for (final boxName in [
        AppConstants.memberBox,
        AppConstants.eventBox,
        AppConstants.attendanceBox,
        AppConstants.permissionBox,
        invitationBoxName,
        AppConstants.pendingUserUpsertBox,
        AppConstants.pendingUserDeleteBox,
        AppConstants.notulensiBox,
      ]) {
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('  - box "$boxName" dihapus');
      }

      // Simpan versi baru
      await settingsBox.put(_schemaVersionKey, _schemaVersion);
      debugPrint('✅ HiveService: schema v$_schemaVersion tersimpan.');
    }

    await settingsBox.close();
  }

  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('⚠️ Error opening Hive box $boxName: $e. Clearing and recreating...');
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError) {
        debugPrint('⚠️ Failed deleting Hive box $boxName: $deleteError');
      }
      return await Hive.openBox<T>(boxName);
    }
  }

  static Box<MemberModel> get members {
    _assertInitialized();
    return Hive.box<MemberModel>(AppConstants.memberBox);
  }

  static Box<EventModel> get events {
    _assertInitialized();
    return Hive.box<EventModel>(AppConstants.eventBox);
  }

  static Box<AttendanceRecord> get attendance {
    _assertInitialized();
    return Hive.box<AttendanceRecord>(AppConstants.attendanceBox);
  }

  static Box<PermissionRecord> get permissions {
    _assertInitialized();
    return Hive.box<PermissionRecord>(AppConstants.permissionBox);
  }

  static Box<EventInvitation> get invitations {
    _assertInitialized();
    return Hive.box<EventInvitation>(invitationBoxName);
  }
  
  static Box<String> get pendingUserUpserts {
    _assertInitialized();
    return Hive.box<String>(AppConstants.pendingUserUpsertBox);
  }

  static Box<String> get pendingUserDeletes {
    _assertInitialized();
    return Hive.box<String>(AppConstants.pendingUserDeleteBox);
  }

  static Box<NotulensiModel> get notulensi {
    _assertInitialized();
    return Hive.box<NotulensiModel>(AppConstants.notulensiBox);
  }

  static void _assertInitialized() {
    assert(_initialized, 'HiveService belum diinisialisasi!');
  }

  static bool get isInitialized => _initialized;

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
}
