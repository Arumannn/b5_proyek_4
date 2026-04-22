// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'member_model.dart';

class MemberModelAdapter extends TypeAdapter<MemberModel> {
  @override
  final int typeId = 0;

  @override
  MemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final memberId = (fields[0] ?? '').toString();
    final nim = fields[2] != null ? fields[2].toString() : memberId;
    return MemberModel(
      memberId: memberId,
      nama: (fields[1] ?? '').toString(),
      nim: nim,
      divisi: (fields[3] ?? '').toString(),
      role: (fields[4] ?? '').toString(),
      password: (fields[5] ?? '').toString(),
      qrCodeValue: (fields[6] ?? '').toString(),
      fcmToken: fields[7]?.toString(),
    );
  }

  @override
  void write(BinaryWriter writer, MemberModel obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.qrCodeValue)
      ..writeByte(7)
      ..write(obj.fcmToken);
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