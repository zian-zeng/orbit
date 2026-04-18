import 'package:hive_flutter/hive_flutter.dart';

part 'skill_registry_entry.g.dart';

@HiveType(typeId: 6)
class SkillRegistryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String skillId;

  @HiveField(2)
  final int version;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String summary;

  @HiveField(6)
  final String systemPrompt;

  @HiveField(7)
  final String starterPrompt;

  @HiveField(8)
  final List<String> toolIds;

  @HiveField(9)
  final List<String> toolLabels;

  @HiveField(10)
  final List<String> toolReasons;

  @HiveField(11)
  final List<String> sourceLabels;

  @HiveField(12)
  final String stressBand;

  @HiveField(13)
  final bool isActive;

  SkillRegistryEntry({
    required this.id,
    required this.skillId,
    required this.version,
    required this.createdAt,
    required this.title,
    required this.summary,
    required this.systemPrompt,
    required this.starterPrompt,
    required this.toolIds,
    required this.toolLabels,
    required this.toolReasons,
    required this.sourceLabels,
    required this.stressBand,
    required this.isActive,
  });

  String get versionLabel => 'v$version';
}
