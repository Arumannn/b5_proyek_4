// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_invitation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventInvitationAdapter extends TypeAdapter<EventInvitation> {
  @override
  final int typeId = 4;

  @override
  EventInvitation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventInvitation(
      eventId: fields[0] as String,
      nim: fields[1] as String,
      responseStatus: fields[2] as String,
      responseMessage: fields[3] as String?,
      respondedAt: fields[4] as DateTime?,
      attendanceStatus: fields[5] as String,
      attendanceTime: fields[6] as DateTime,
      invitedBy: fields[7] as String,
      invitedAt: fields[8] as DateTime,
      isRequired: fields[9] as bool,
      isSynced: fields[10] as bool,
      organizationId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventInvitation obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.nim)
      ..writeByte(2)
      ..write(obj.responseStatus)
      ..writeByte(3)
      ..write(obj.responseMessage)
      ..writeByte(4)
      ..write(obj.respondedAt)
      ..writeByte(5)
      ..write(obj.attendanceStatus)
      ..writeByte(6)
      ..write(obj.attendanceTime)
      ..writeByte(7)
      ..write(obj.invitedBy)
      ..writeByte(8)
      ..write(obj.invitedAt)
      ..writeByte(9)
      ..write(obj.isRequired)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.organizationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventInvitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
