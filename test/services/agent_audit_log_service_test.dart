import 'dart:io';

import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:chatbotapp/services/agent_audit_log_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-audit-test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AgentAuditLogEntryAdapter());
    }
    await Hive.openBox<AgentAuditLogEntry>(Constants.agentAuditLogBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('records agent audit details for an assistant message', () async {
    const service = AgentAuditLogService();
    final message = _assistantMessage();

    await service.record(
      assistantMessage: message,
      userMessage: 'I need vegan food and a study plan.',
      response: _response(),
      snapshot: _snapshot(),
      labelKeys: const ['vegan', 'academic_planning'],
      latencyMs: 1234,
      now: DateTime(2026, 4, 18, 10),
    );

    final audit = service.loadForMessage(message);

    expect(audit, isNotNull);
    expect(audit!.activatedRoles, contains('Academic planning'));
    expect(audit.toolNames, contains('live_places_search'));
    expect(audit.dataSources, contains('Canvas'));
    expect(audit.dataSources, contains('Google Places'));
    expect(audit.labelKeys, contains('vegan'));
    expect(audit.latencyMs, 1234);
  });

  test('upserts audit details for the same assistant message', () async {
    const service = AgentAuditLogService();
    final message = _assistantMessage();

    await service.record(
      assistantMessage: message,
      userMessage: 'First',
      response: _response(modelName: 'gemma2:2b'),
      snapshot: StudentSignalSnapshot.empty(),
      labelKeys: const [],
      latencyMs: 10,
    );
    await service.record(
      assistantMessage: message,
      userMessage: 'Second',
      response: _response(modelName: 'qwen2.5:3b'),
      snapshot: StudentSignalSnapshot.empty(),
      labelKeys: const ['planning'],
      latencyMs: 20,
    );

    final recent = service.loadRecent();

    expect(recent, hasLength(1));
    expect(recent.single.modelName, 'qwen2.5:3b');
    expect(recent.single.latencyMs, 20);
  });
}

Message _assistantMessage() {
  return Message(
    messageId: 'assistant-1',
    chatId: 'chat-1',
    role: Role.assistant,
    message: StringBuffer('Answer'),
    imagesUrls: const [],
    timeSent: DateTime(2026, 4, 18),
  );
}

OrbitAgentResponse _response({String modelName = 'gemma2:2b'}) {
  return OrbitAgentResponse(
    text: 'Try a small first step.',
    trace: OrbitAgentTrace(
      activatedRoles: const [
        OrbitAgentRole.workflowController,
        OrbitAgentRole.academicPlanning,
        OrbitAgentRole.synthesizer,
      ],
      skillResults: const [
        SkillResult(
          skillId: 'runtime.skill.auto.direct',
          role: OrbitAgentRole.workflowController,
          title: 'Adaptive runtime skill',
          summary: 'Generated from labels.',
          recommendations: [
            'Tool priority: chat_history_lookup -> live_places_search',
          ],
          confidence: 0.9,
        ),
      ],
      usedLocalModel: true,
      modelName: modelName,
      fallbackReason: null,
    ),
  );
}

StudentSignalSnapshot _snapshot() {
  return StudentSignalSnapshot(
    fetchedAt: DateTime(2026, 4, 18),
    assignments: [
      StudentAssignment(
        id: 'a1',
        courseId: 'cmsc131',
        name: 'Project',
        dueAt: DateTime(2026, 4, 19),
      ),
    ],
    calendarEvents: const [],
    routes: const [],
    places: const [
      CampusPlace(
        name: 'Plant Cafe',
        formattedAddress: 'College Park, MD',
        reason: 'Matched live Google Places query: vegan food near UMD',
      ),
    ],
    sourceNotes: const [],
  );
}
