// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitor_history_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonitorHistoryEntryAdapter extends TypeAdapter<MonitorHistoryEntry> {
  @override
  final int typeId = 3;

  @override
  MonitorHistoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonitorHistoryEntry(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      studentEmail: fields[2] as String,
      source: fields[3] as String,
      stressScore: fields[4] as double,
      deadlines: fields[5] as int,
      calendarHours: fields[6] as double,
      placeCount: fields[7] as int,
      routeCount: fields[8] as int,
      labels: (fields[9] as List?)?.cast<String>() ?? const [],
      sourceNote: fields[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, MonitorHistoryEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.studentEmail)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.stressScore)
      ..writeByte(5)
      ..write(obj.deadlines)
      ..writeByte(6)
      ..write(obj.calendarHours)
      ..writeByte(7)
      ..write(obj.placeCount)
      ..writeByte(8)
      ..write(obj.routeCount)
      ..writeByte(9)
      ..write(obj.labels)
      ..writeByte(10)
      ..write(obj.sourceNote);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitorHistoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
