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
      invitationId: fields[0] as String,
      eventId: fields[1] as String,
      nim: fields[2] as String,
      responseStatus: fields[3] as String,
      responseMessage: fields[4] as String?,
      respondedAt: fields[5] as DateTime?,
      attendanceStatus: fields[6] as String,
      attendanceTime: fields[7] as DateTime,
      invitedBy: fields[8] as String,
      invitedAt: fields[9] as DateTime,
      isRequired: fields[10] as bool,
      isSynced: fields[11] as bool,
      organizationId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventInvitation obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.invitationId)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.nim)
      ..writeByte(3)
      ..write(obj.responseStatus)
      ..writeByte(4)
      ..write(obj.responseMessage)
      ..writeByte(5)
      ..write(obj.respondedAt)
      ..writeByte(6)
      ..write(obj.attendanceStatus)
      ..writeByte(7)
      ..write(obj.attendanceTime)
      ..writeByte(8)
      ..write(obj.invitedBy)
      ..writeByte(9)
      ..write(obj.invitedAt)
      ..writeByte(10)
      ..write(obj.isRequired)
      ..writeByte(11)
      ..write(obj.isSynced)
      ..writeByte(12)
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
