import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:chatbotapp/services/support_intelligence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SupportIntelligenceService();

  test('builds high-stress questions, suggestions, and a skill blueprint', () {
    final bundle = service.buildBundle(
      routingLabelKeys: const ['wellbeing_checkin', 'planning'],
      recentLabelKeys: const ['wellbeing_checkin', 'planning'],
      labelSignalSources: const ['Google Calendar', 'Canvas'],
      history: [
        ChatHistory(
          chatId: 'chat-1',
          prompt: 'I am overwhelmed by exams and deadlines.',
          response: 'Let us slow this down.',
          imagesUrls: const [],
          timestamp: DateTime(2026, 4, 17),
          selectedLabel: 'wellbeing_checkin',
          templateId: 'template.wellbeing_checkin',
        ),
      ],
    );

    expect(bundle, isNotNull);
    expect(bundle!.stressReport.band, StressBand.high);
    expect(bundle.questions, hasLength(2));
    expect(bundle.suggestions, hasLength(2));
    expect(bundle.skill.tools.map((tool) => tool.toolId), contains('chat_history_lookup'));
    expect(bundle.skill.tools.map((tool) => tool.toolId), contains('calendar_signal_review'));
  });

  test('returns null without routing labels', () {
    final bundle = service.buildBundle(
      routingLabelKeys: const [],
      recentLabelKeys: const [],
      labelSignalSources: const [],
      history: const [],
    );

    expect(bundle, isNull);
  });
}
