import 'package:hive_flutter/hive_flutter.dart';

part 'monitor_history_entry.g.dart';

@HiveType(typeId: 3)
class MonitorHistoryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final String studentEmail;

  @HiveField(3)
  final String source;

  @HiveField(4)
  final double stressScore;

  @HiveField(5)
  final int deadlines;

  @HiveField(6)
  final double calendarHours;

  @HiveField(7)
  final int placeCount;

  @HiveField(8)
  final int routeCount;

  @HiveField(9)
  final List<String> labels;

  @HiveField(10)
  final String sourceNote;

  MonitorHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.studentEmail,
    required this.source,
    required this.stressScore,
    required this.deadlines,
    required this.calendarHours,
    required this.placeCount,
    required this.routeCount,
    required this.labels,
    required this.sourceNote,
  });

  String get dayLabel => '${createdAt.month}/${createdAt.day}';
}
