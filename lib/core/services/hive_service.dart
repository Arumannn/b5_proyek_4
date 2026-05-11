import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../models/member_model.dart';
import '../../models/event_model.dart';
import '../../models/attendance_record.dart';
import '../../models/permission_record.dart';
import '../../models/event_invitation.dart';

class HiveService {
  HiveService._();

  static bool _initialized = false;
  static const String invitationBoxName = 'invitations';

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

    await _openBoxSafely<MemberModel>(AppConstants.memberBox);
    await _openBoxSafely<EventModel>(AppConstants.eventBox);
    await _openBoxSafely<AttendanceRecord>(AppConstants.attendanceBox);
    await _openBoxSafely<PermissionRecord>(AppConstants.permissionBox);
    await _openBoxSafely<EventInvitation>(invitationBoxName);
    await _openBoxSafely<String>(AppConstants.pendingUserUpsertBox);
    await _openBoxSafely<String>(AppConstants.pendingUserDeleteBox);

    _initialized = true;
    debugPrint('✅ HiveService initialized — 4 boxes open');
  }

  static Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint('⚠️ Error opening Hive box $boxName: $e. Clearing and recreating...');
      await Hive.deleteBoxFromDisk(boxName);
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

  static void _assertInitialized() {
    assert(_initialized, 'HiveService belum diinisialisasi!');
  }

  static bool get isInitialized => _initialized;

  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }
}
