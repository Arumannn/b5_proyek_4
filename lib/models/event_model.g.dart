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
      tanggalMulai: fields[4] as DateTime,
      tanggalSelesai: fields[5] as DateTime?,
      deskripsi: fields[6] as String?,
      targetPeserta: (fields[7] as List?)?.cast<String>(),
      createdBy: fields[8] as String,
      isSynced: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
      jamMulai: fields[11] as DateTime?,
      jamSelesai: fields[12] as DateTime?,
      lokasi: fields[13] as String?,
      statusEvent: fields[14] as String?,
      penyelenggara: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.eventId)
      ..writeByte(1)
      ..write(obj.parentEventId)
      ..writeByte(2)
      ..write(obj.nama)
      ..writeByte(3)
      ..write(obj.jenis)
      ..writeByte(4)
      ..write(obj.tanggalMulai)
      ..writeByte(5)
      ..write(obj.tanggalSelesai)
      ..writeByte(6)
      ..write(obj.deskripsi)
      ..writeByte(7)
      ..write(obj.targetPeserta)
      ..writeByte(8)
      ..write(obj.createdBy)
      ..writeByte(9)
      ..write(obj.isSynced)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.jamMulai)
      ..writeByte(12)
      ..write(obj.jamSelesai)
      ..writeByte(13)
      ..write(obj.lokasi)
      ..writeByte(14)
      ..write(obj.statusEvent)
      ..writeByte(15)
      ..write(obj.penyelenggara);
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
