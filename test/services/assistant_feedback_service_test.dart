import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:chatbotapp/services/assistant_feedback_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-feedback-test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AssistantFeedbackEntryAdapter());
    }
    await Hive.openBox<AssistantFeedbackEntry>(Constants.assistantFeedbackBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('records and loads feedback for an assistant message', () async {
    const service = AssistantFeedbackService();
    final message = _assistantMessage();

    await service.recordFeedback(
      message: message,
      feedbackType: 'helpful',
      visibleText: 'This helped me plan the next step.',
      agentTrace: 'agents=academic,stress tools=calendar',
      now: DateTime(2026, 4, 18, 10),
    );

    final feedback = service.loadForMessage(message);

    expect(feedback, isNotNull);
    expect(feedback!.feedbackType, 'helpful');
    expect(feedback.agentTrace, contains('academic'));
    expect(feedback.responsePreview, contains('next step'));
  });

  test('upserts feedback for the same assistant message', () async {
    const service = AssistantFeedbackService();
    final message = _assistantMessage();

    await service.recordFeedback(
      message: message,
      feedbackType: 'helpful',
      visibleText: 'First response',
      agentTrace: '',
    );
    await service.recordFeedback(
      message: message,
      feedbackType: 'wrong_context',
      visibleText: 'Updated response',
      agentTrace: '',
    );

    final entries = service.loadRecent();

    expect(entries, hasLength(1));
    expect(entries.single.feedbackType, 'wrong_context');
  });

  test('summarizes recent feedback counts', () async {
    const service = AssistantFeedbackService();
    final first = _assistantMessage(messageId: '1');
    final second = _assistantMessage(messageId: '2');

    await service.recordFeedback(
      message: first,
      feedbackType: 'helpful',
      visibleText: 'Good',
      agentTrace: '',
    );
    await service.recordFeedback(
      message: second,
      feedbackType: 'too_much',
      visibleText: 'Too long',
      agentTrace: '',
    );

    final counts = service.feedbackCounts();

    expect(counts['helpful'], 1);
    expect(counts['too_much'], 1);
  });
}

Message _assistantMessage({String messageId = 'assistant-1'}) {
  return Message(
    messageId: messageId,
    chatId: 'chat-1',
    role: Role.assistant,
    message: StringBuffer('Answer'),
    imagesUrls: const [],
    timeSent: DateTime(2026, 4, 18),
  );
}
