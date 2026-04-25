// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 1;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      eventId: fields[0] as String,
      parentEventId: fields[1] as String?,
      nama: fields[2] as String,
      jenis: fields[3] as String,
      tanggal: fields[4] as DateTime,
      deskripsi: fields[5] as String?,
      targetPeserta: (fields[6] as List?)?.cast<String>(),
      createdBy: fields[7] as String,
      isSynced: fields[8] as bool,
      createdAt: fields[9] as DateTime?,
      jamMulai: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.parentEventId)
      ..writeByte(2)
      ..write(obj.nama)
      ..writeByte(3)
      ..write(obj.jenis)
      ..writeByte(4)
      ..write(obj.tanggal)
      ..writeByte(5)
      ..write(obj.deskripsi)
      ..writeByte(6)
      ..write(obj.targetPeserta)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.isSynced)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.jamMulai);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
