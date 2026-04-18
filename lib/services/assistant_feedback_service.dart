import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:hive/hive.dart';

class AssistantFeedbackService {
  const AssistantFeedbackService();

  Future<AssistantFeedbackEntry?> recordFeedback({
    required Message message,
    required String feedbackType,
    required String visibleText,
    required String agentTrace,
    DateTime? now,
  }) async {
    if (!Hive.isBoxOpen(Constants.assistantFeedbackBox)) {
      return null;
    }
    final entry = AssistantFeedbackEntry(
      id: _feedbackId(message),
      chatId: message.chatId,
      messageId: message.messageId,
      feedbackType: feedbackType,
      createdAt: now ?? DateTime.now(),
      responsePreview: _preview(visibleText),
      agentTrace: agentTrace,
    );
    await Boxes.getAssistantFeedback().put(entry.id, entry);
    return entry;
  }

  AssistantFeedbackEntry? loadForMessage(Message message) {
    if (!Hive.isBoxOpen(Constants.assistantFeedbackBox)) {
      return null;
    }
    return Boxes.getAssistantFeedback().get(_feedbackId(message));
  }

  List<AssistantFeedbackEntry> loadRecent({int limit = 50}) {
    if (!Hive.isBoxOpen(Constants.assistantFeedbackBox)) {
      return const [];
    }
    final entries = Boxes.getAssistantFeedback().values.toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return entries.take(limit).toList(growable: false);
  }

  Map<String, int> feedbackCounts({int limit = 200}) {
    final counts = <String, int>{};
    for (final entry in loadRecent(limit: limit)) {
      counts[entry.feedbackType] = (counts[entry.feedbackType] ?? 0) + 1;
    }
    return counts;
  }

  String _feedbackId(Message message) {
    return '${message.chatId}|${message.messageId}';
  }

  String _preview(String text) {
    final normalized = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 240) {
      return normalized;
    }
    return normalized.substring(0, 240);
  }
}
