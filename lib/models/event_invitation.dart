import 'package:hive/hive.dart';
import '../core/enums/status_enums.dart';
part 'event_invitation.g.dart';

@HiveType(typeId: 4)
class EventInvitation {
    @HiveField(0)
    final String eventId;

    @HiveField(1)
    final String nim;

    @HiveField(2)
    String responseStatus;

    InvitationStatus get responseStatusEnum => InvitationStatus.fromString(responseStatus);
    set responseStatusEnum(InvitationStatus val) => responseStatus = val.value;

    @HiveField(3)
    String? responseMessage;

    @HiveField(4)
    DateTime? respondedAt;

    @HiveField(5)
    String attendanceStatus;

    AttendanceStatus get attendanceStatusEnum => AttendanceStatus.fromString(attendanceStatus);
    set attendanceStatusEnum(AttendanceStatus val) => attendanceStatus = val.value;

    @HiveField(6)
    DateTime attendanceTime;

    @HiveField(7)
    final String invitedBy;

    @HiveField(8)
    final DateTime invitedAt;

    @HiveField(9)
    final bool isRequired;

    @HiveField(10)
    bool isSynced;

    @HiveField(11)
    final String? organizationId;

    String get compositeKey => '${eventId}_$nim';

    EventInvitation({
        required this.eventId,
        required this.nim,
        this.responseStatus = 'pending',
        this.responseMessage,
        this.respondedAt,
        this.attendanceStatus = 'not_marked',
        required this.attendanceTime,
        required this.invitedBy,
        required this.invitedAt,
        this.isRequired = true,
        this.isSynced = false,
        this.organizationId,
    });

    factory EventInvitation.fromJson(Map<String, dynamic> json) {
        DateTime? parseDate(dynamic value) {
            if (value == null) return null;
            if (value is DateTime) return value;
            return DateTime.tryParse(value.toString());
        }

        return EventInvitation(
            eventId: (json['eventId'] ?? '').toString(),
            nim: (json['nim'] ?? '').toString(),
            responseStatus: (json['responseStatus'] ?? 'pending').toString(),
            responseMessage: json['responseMessage']?.toString(),
            respondedAt: parseDate(json['respondedAt']),
            attendanceStatus: (json['attendanceStatus'] ?? 'not_marked').toString(),
            attendanceTime: parseDate(json['attendanceTime']) ?? DateTime.now(),
            invitedBy: (json['invitedBy'] ?? '').toString(),
            invitedAt: parseDate(json['invitedAt']) ?? DateTime.now(),
            isRequired: json['isRequired'] == true,
            isSynced: json['isSynced'] == true,
            organizationId: json['organizationId']?.toString(),
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'eventId': eventId,
            'nim': nim,
            'responseStatus': responseStatus,
            'responseMessage': responseMessage,
            'respondedAt': respondedAt?.toIso8601String(),
            'attendanceStatus': attendanceStatus,
            'attendanceTime': attendanceTime.toIso8601String(),
            'invitedBy': invitedBy,
            'invitedAt': invitedAt.toIso8601String(),
            'isRequired': isRequired,
            'organizationId': organizationId,
        };
    }
}