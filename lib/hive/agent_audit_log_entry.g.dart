// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_audit_log_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgentAuditLogEntryAdapter extends TypeAdapter<AgentAuditLogEntry> {
  @override
  final int typeId = 5;

  @override
  AgentAuditLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AgentAuditLogEntry(
      id: fields[0] as String,
      chatId: fields[1] as String,
      messageId: fields[2] as String,
      createdAt: fields[3] as DateTime,
      activatedRoles: (fields[4] as List?)?.cast<String>() ?? const [],
      skillIds: (fields[5] as List?)?.cast<String>() ?? const [],
      toolNames: (fields[6] as List?)?.cast<String>() ?? const [],
      dataSources: (fields[7] as List?)?.cast<String>() ?? const [],
      labelKeys: (fields[8] as List?)?.cast<String>() ?? const [],
      usedLocalModel: fields[9] as bool? ?? false,
      modelName: fields[10] as String? ?? '',
      fallbackReason: fields[11] as String? ?? '',
      latencyMs: fields[12] as int? ?? 0,
      userMessagePreview: fields[13] as String? ?? '',
      responsePreview: fields[14] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AgentAuditLogEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.messageId)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.activatedRoles)
      ..writeByte(5)
      ..write(obj.skillIds)
      ..writeByte(6)
      ..write(obj.toolNames)
      ..writeByte(7)
      ..write(obj.dataSources)
      ..writeByte(8)
      ..write(obj.labelKeys)
      ..writeByte(9)
      ..write(obj.usedLocalModel)
      ..writeByte(10)
      ..write(obj.modelName)
      ..writeByte(11)
      ..write(obj.fallbackReason)
      ..writeByte(12)
      ..write(obj.latencyMs)
      ..writeByte(13)
      ..write(obj.userMessagePreview)
      ..writeByte(14)
      ..write(obj.responsePreview);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgentAuditLogEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
