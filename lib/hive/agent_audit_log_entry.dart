import 'package:hive_flutter/hive_flutter.dart';

part 'agent_audit_log_entry.g.dart';

@HiveType(typeId: 5)
class AgentAuditLogEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String messageId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final List<String> activatedRoles;

  @HiveField(5)
  final List<String> skillIds;

  @HiveField(6)
  final List<String> toolNames;

  @HiveField(7)
  final List<String> dataSources;

  @HiveField(8)
  final List<String> labelKeys;

  @HiveField(9)
  final bool usedLocalModel;

  @HiveField(10)
  final String modelName;

  @HiveField(11)
  final String fallbackReason;

  @HiveField(12)
  final int latencyMs;

  @HiveField(13)
  final String userMessagePreview;

  @HiveField(14)
  final String responsePreview;

  AgentAuditLogEntry({
    required this.id,
    required this.chatId,
    required this.messageId,
    required this.createdAt,
    required this.activatedRoles,
    required this.skillIds,
    required this.toolNames,
    required this.dataSources,
    required this.labelKeys,
    required this.usedLocalModel,
    required this.modelName,
    required this.fallbackReason,
    required this.latencyMs,
    required this.userMessagePreview,
    required this.responsePreview,
  });
}
