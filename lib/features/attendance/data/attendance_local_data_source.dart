import '../../../core/services/hive_service.dart';
import '../../../models/attendance_record.dart';
import '../../../models/event_model.dart';
import '../../../models/member_model.dart';

class AttendanceLocalDataSource {
  EventModel? getEvent(String eventId) {
    return HiveService.events.get(eventId);
  }

  bool isMainEventWithSubEvents(String eventId) {
    final event = HiveService.events.get(eventId);
    if (event == null) return false;
    
    final isMainEvent = event.parentEventId == null;
    if (!isMainEvent) return false;

    return HiveService.events.values.any((e) => e.parentEventId == eventId);
  }

  bool hasAttendance(String compositeKey) {
    return HiveService.attendance.values.any(
      (r) => r.compositeKey == compositeKey,
    );
  }

  Future<void> saveAttendance(AttendanceRecord record) async {
    await HiveService.attendance.add(record);
  }

  List<AttendanceRecord> getAttendanceByEvent(String eventId) {
    return HiveService.attendance.values
        .where((r) => r.eventId == eventId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<AttendanceRecord> getAttendanceByMember(String nim) {
    return HiveService.attendance.values
        .where((r) => r.nim == nim)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  AttendanceRecord? getAttendanceByRecordId(String recordId) {
    try {
      return HiveService.attendance.values.firstWhere(
        (r) => r.recordId == recordId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAttendance(AttendanceRecord record) async {
    await record.save(); // HiveObject save
  }

  Future<void> deleteAttendance(AttendanceRecord record) async {
    await record.delete();
  }

  List<MemberModel> getAllMembers() {
    return HiveService.members.values.toList();
  }

  MemberModel? getMemberByNim(String nim) {
    return HiveService.members.get(nim);
  }

  Future<void> saveMember(MemberModel member) async {
    await HiveService.members.put(member.nim, member);
  }
}
