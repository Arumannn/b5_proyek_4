// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoleConfigAdapter extends TypeAdapter<RoleConfig> {
  @override
  final int typeId = 9;

  @override
  RoleConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoleConfig(
      roleName: fields[0] as String,
      permissions: (fields[1] as List).cast<String>(),
      allowedDivisions: (fields[2] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RoleConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.roleName)
      ..writeByte(1)
      ..write(obj.permissions)
      ..writeByte(2)
      ..write(obj.allowedDivisions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OrganizationConfigAdapter extends TypeAdapter<OrganizationConfig> {
  @override
  final int typeId = 10;

  @override
  OrganizationConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrganizationConfig(
      organizationId: fields[0] as String,
      eventTypes: (fields[1] as List).cast<String>(),
      rolesConfig: (fields[2] as List).cast<RoleConfig>(),
    );
  }

  @override
  void write(BinaryWriter writer, OrganizationConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.organizationId)
      ..writeByte(1)
      ..write(obj.eventTypes)
      ..writeByte(2)
      ..write(obj.rolesConfig);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
