// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notulensi_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotulensiModelAdapter extends TypeAdapter<NotulensiModel> {
  @override
  final int typeId = 8;

  @override
  NotulensiModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotulensiModel(
      eventId: fields[0] as String,
      content: fields[1] as String,
      updatedAt: fields[2] as DateTime,
      updatedBy: fields[3] as String,
      isSynced: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotulensiModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.updatedBy)
      ..writeByte(4)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotulensiModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
