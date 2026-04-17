import 'dart:convert';
import 'dart:io';

import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/services/support_intelligence_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = SupportIntelligenceService();

  test('evaluation fixture meets fulfillment thresholds', () {
    final fixturePath =
        File('test/fixtures/support_intelligence_eval_dataset.json');
    final raw = jsonDecode(fixturePath.readAsStringSync()) as List<dynamic>;
    final cases = raw.cast<Map<String, dynamic>>();

    expect(cases.length, inInclusiveRange(30, 50));

    var labelMatches = 0;
    var stressMatches = 0;
    var toolMatches = 0;
    var promptMatches = 0;

    for (final item in cases) {
      final history = (item['history'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(
            (entry) => ChatHistory(
              chatId: entry['chat_id'] as String,
              prompt: entry['prompt'] as String,
              response: entry['response'] as String,
              imagesUrls: const [],
              timestamp: DateTime(2026, 4, 17),
              selectedLabel: entry['selected_label'] as String?,
              templateId: entry['template_id'] as String?,
            ),
          )
          .toList(growable: false);

      final bundle = service.buildBundle(
        routingLabelKeys:
            (item['routing_label_keys'] as List<dynamic>).cast<String>(),
        recentLabelKeys:
            (item['recent_label_keys'] as List<dynamic>).cast<String>(),
        labelSignalSources:
            (item['label_signal_sources'] as List<dynamic>).cast<String>(),
        history: history,
      );

      expect(bundle, isNotNull);
      final supportBundle = bundle!;
      final expectedPrimary = item['expected_primary_label'] as String;
      final expectedStressBand = item['expected_stress_band'] as String;
      final expectedTools =
          (item['expected_tool_ids'] as List<dynamic>).cast<String>();
      final expectedKeyword =
          (item['expected_prompt_keyword'] as String).toLowerCase();

      if (supportBundle.primaryLabel.storageKey == expectedPrimary) {
        labelMatches++;
      }
      if (supportBundle.stressReport.band.name == expectedStressBand) {
        stressMatches++;
      }
      final toolIds =
          supportBundle.skill.tools.map((tool) => tool.toolId).toSet();
      if (expectedTools.every(toolIds.contains)) {
        toolMatches++;
      }
      final promptText = [
        ...supportBundle.questions.map((item) => item.prompt),
        ...supportBundle.suggestions.map((item) => item.prompt),
        supportBundle.skill.systemPrompt,
      ].join(' ').toLowerCase();
      if (promptText.contains(expectedKeyword)) {
        promptMatches++;
      }
    }

    final total = cases.length.toDouble();
    expect(labelMatches / total, greaterThanOrEqualTo(0.95));
    expect(stressMatches / total, greaterThanOrEqualTo(0.5));
    expect(toolMatches / total, greaterThanOrEqualTo(0.9));
    expect(promptMatches / total, greaterThanOrEqualTo(0.75));
  });
}
