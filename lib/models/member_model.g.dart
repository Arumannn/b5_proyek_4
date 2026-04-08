// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemberModelAdapter extends TypeAdapter<MemberModel> {
  @override
  final int typeId = 0;

  @override
  MemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemberModel(
      memberId: fields[0] as String,
      nama: fields[1] as String,
      nim: fields[2] as String,
      divisi: fields[3] as String,
      role: fields[4] as String,
      password: fields[5] as String,
      qrData: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MemberModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.memberId)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.nim)
      ..writeByte(3)
      ..write(obj.divisi)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.password)
      ..writeByte(6)
      ..write(obj.qrData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
