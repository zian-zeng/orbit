// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_feedback_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssistantFeedbackEntryAdapter
    extends TypeAdapter<AssistantFeedbackEntry> {
  @override
  final int typeId = 4;

  @override
  AssistantFeedbackEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssistantFeedbackEntry(
      id: fields[0] as String,
      chatId: fields[1] as String,
      messageId: fields[2] as String,
      feedbackType: fields[3] as String,
      createdAt: fields[4] as DateTime,
      responsePreview: fields[5] as String? ?? '',
      agentTrace: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, AssistantFeedbackEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.chatId)
      ..writeByte(2)
      ..write(obj.messageId)
      ..writeByte(3)
      ..write(obj.feedbackType)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.responsePreview)
      ..writeByte(6)
      ..write(obj.agentTrace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssistantFeedbackEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
