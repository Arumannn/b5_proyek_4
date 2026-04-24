// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PermissionRecordAdapter extends TypeAdapter<PermissionRecord> {
  @override
  final int typeId = 3;

  @override
  PermissionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PermissionRecord(
      permissionId: fields[0] as String,
      eventId: fields[1] as String,
      memberId: fields[2] as String,
      jenisIzin: fields[3] as String,
      alasan: fields[4] as String,
      buktiFotoPath: fields[5] as String?,
      buktiFotoUrl: fields[6] as String?,
      status: fields[7] as String,
      validatedBy: fields[8] as String?,
      isSynced: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PermissionRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.permissionId)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.memberId)
      ..writeByte(3)
      ..write(obj.jenisIzin)
      ..writeByte(4)
      ..write(obj.alasan)
      ..writeByte(5)
      ..write(obj.buktiFotoPath)
      ..writeByte(6)
      ..write(obj.buktiFotoUrl)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.validatedBy)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PermissionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
