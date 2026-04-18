// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_registry_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SkillRegistryEntryAdapter extends TypeAdapter<SkillRegistryEntry> {
  @override
  final int typeId = 6;

  @override
  SkillRegistryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SkillRegistryEntry(
      id: fields[0] as String,
      skillId: fields[1] as String,
      version: fields[2] as int,
      createdAt: fields[3] as DateTime,
      title: fields[4] as String,
      summary: fields[5] as String,
      systemPrompt: fields[6] as String,
      starterPrompt: fields[7] as String,
      toolIds: (fields[8] as List?)?.cast<String>() ?? const [],
      toolLabels: (fields[9] as List?)?.cast<String>() ?? const [],
      toolReasons: (fields[10] as List?)?.cast<String>() ?? const [],
      sourceLabels: (fields[11] as List?)?.cast<String>() ?? const [],
      stressBand: fields[12] as String? ?? '',
      isActive: fields[13] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SkillRegistryEntry obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.skillId)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.systemPrompt)
      ..writeByte(7)
      ..write(obj.starterPrompt)
      ..writeByte(8)
      ..write(obj.toolIds)
      ..writeByte(9)
      ..write(obj.toolLabels)
      ..writeByte(10)
      ..write(obj.toolReasons)
      ..writeByte(11)
      ..write(obj.sourceLabels)
      ..writeByte(12)
      ..write(obj.stressBand)
      ..writeByte(13)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillRegistryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
