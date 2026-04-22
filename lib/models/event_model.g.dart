// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'event_model.dart';

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 1;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    List<String> parsePeserta(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return EventModel(
      eventId: (fields[0] ?? '').toString(),
      parentEventId: fields[1]?.toString(),
      nama: (fields[2] ?? '').toString(),
      jenis: (fields[3] ?? 'Kegiatan').toString(),
      tanggal: fields[4] as DateTime? ?? DateTime.now(),
      deskripsi: fields[5]?.toString(),
      targetPeserta: parsePeserta(fields[6]),
      createdBy: (fields[7] ?? 'system').toString(),
      isSynced: fields[8] as bool? ?? false,
      createdAt: fields[9] as DateTime? ?? DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.createdAt);
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