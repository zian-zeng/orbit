import 'package:hive_flutter/hive_flutter.dart';

part 'assistant_feedback_entry.g.dart';

@HiveType(typeId: 4)
class AssistantFeedbackEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String chatId;

  @HiveField(2)
  final String messageId;

  @HiveField(3)
  final String feedbackType;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final String responsePreview;

  @HiveField(6)
  final String agentTrace;

  AssistantFeedbackEntry({
    required this.id,
    required this.chatId,
    required this.messageId,
    required this.feedbackType,
    required this.createdAt,
    required this.responsePreview,
    required this.agentTrace,
  });
}
