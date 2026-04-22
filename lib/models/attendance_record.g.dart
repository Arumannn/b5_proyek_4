// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'attendance_record.dart';

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
      recordId: (fields[0] ?? '').toString(),
      eventId: (fields[1] ?? '').toString(),
      memberId: (fields[2] ?? '').toString(),
      timestamp: fields[3] as DateTime? ?? DateTime.now(),
      status: (fields[4] ?? 'Hadir').toString(),
      isManualOverride: fields[5] as bool? ?? false,
      overrideBy: fields[6]?.toString(),
      isSynced: fields[7] as bool? ?? false,
      compositeKey: (fields[8] ?? '').toString(),
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.recordId)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.memberId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.isManualOverride)
      ..writeByte(6)
      ..write(obj.overrideBy)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.compositeKey);
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