// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'permission_record.dart';

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
      permissionId: (fields[0] ?? '').toString(),
      eventId: (fields[1] ?? '').toString(),
      memberId: (fields[2] ?? '').toString(),
      jenisIzin: (fields[3] ?? 'Izin').toString(),
      alasan: (fields[4] ?? '').toString(),
      buktiFotoPath: fields[5]?.toString(),
      buktiFotoUrl: fields[6]?.toString(),
      status: (fields[7] ?? 'Pending').toString(),
      validatedBy: fields[8]?.toString(),
      isSynced: fields[9] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PermissionRecord obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.isSynced);
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