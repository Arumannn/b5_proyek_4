// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceRecordAdapter extends TypeAdapter<AttendanceRecord> {
  @override
  final int typeId = 2;

  @override
  AttendanceRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceRecord(
      recordId: fields[0] as String,
      eventId: fields[1] as String,
      nim: fields[2] as String,
      timestamp: fields[3] as DateTime,
      isSynced: fields[4] as bool,
      compositeKey: fields[5] as String,
      memberId: fields[6] as String,
      status: fields[7] as String,
      isManualOverride: fields[8] as bool,
      overrideBy: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.recordId)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.nim)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.compositeKey)
      ..writeByte(6)
      ..write(obj.memberId)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.isManualOverride)
      ..writeByte(9)
      ..write(obj.overrideBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
