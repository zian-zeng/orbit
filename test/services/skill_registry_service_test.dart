import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:chatbotapp/services/skill_registry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-skill-test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SkillRegistryEntryAdapter());
    }
    await Hive.openBox<SkillRegistryEntry>(Constants.skillRegistryBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves generated skills with version numbers', () async {
    const service = SkillRegistryService();
    final blueprint = _blueprint();

    final first = await service.saveBlueprint(
      blueprint: blueprint,
      sourceLabels: const ['planning', 'wellbeing_checkin'],
      stressBand: StressBand.high,
      now: DateTime(2026, 4, 18, 10),
    );
    final second = await service.saveBlueprint(
      blueprint: blueprint,
      sourceLabels: const ['planning', 'wellbeing_checkin'],
      stressBand: StressBand.high,
      now: DateTime(2026, 4, 18, 11),
    );

    expect(first!.version, 1);
    expect(second!.version, 2);
    expect(second.versionLabel, 'v2');
    expect(second.toolIds, contains('chat_history_lookup'));
  });

  test('loads latest saved version for a skill', () async {
    const service = SkillRegistryService();
    final blueprint = _blueprint();

    await service.saveBlueprint(
      blueprint: blueprint,
      sourceLabels: const ['planning'],
      stressBand: StressBand.elevated,
    );
    final latest = await service.saveBlueprint(
      blueprint: blueprint,
      sourceLabels: const ['planning'],
      stressBand: StressBand.elevated,
    );

    expect(service.latestForSkill(blueprint.skillId)?.id, latest!.id);
    expect(service.loadRecent(), hasLength(2));
  });
}

AgentSkillBlueprint _blueprint() {
  return const AgentSkillBlueprint(
    skillId: 'support_planning_high_router',
    title: 'Planning Support Router',
    summary: 'Route planning and stress support.',
    systemPrompt: 'Ask one clarifying question.',
    starterPrompt: 'Help me plan the next step.',
    tools: [
      AgentToolSuggestion(
        toolId: 'chat_history_lookup',
        label: 'History lookup',
        reason: 'Ground the next question.',
      ),
      AgentToolSuggestion(
        toolId: 'stress_report_summarizer',
        label: 'Stress report',
        reason: 'Use the current stress band.',
      ),
    ],
  );
}
