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
    final nim = (fields[0] ?? fields[2] ?? '').toString();
    return MemberModel(
      nim: nim,
      nama: (fields[1] ?? '').toString(),
      divisi: (fields[2] ?? fields[3] ?? '').toString(),
      role: (fields[3] ?? fields[4] ?? '').toString(),
      password: (fields[4] ?? fields[5] ?? '').toString(),
      qrData: (fields[5] ?? fields[6] ?? '').toString(),
    );
  }

  @override
  void write(BinaryWriter writer, MemberModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nim)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.divisi)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
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
