import 'package:chatbotapp/agents/local_llm_client.dart';
import 'package:chatbotapp/agents/orbit_agent_orchestrator.dart';
import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('activates academic and stress roles for deadline pressure', () async {
    final orchestrator = OrbitAgentOrchestrator(
      llmClient: const _FakeLocalLlmClient('Here is a calm plan.'),
    );

    final response = await orchestrator.respond(
      const OrbitAgentRequest(
        message: 'I am overwhelmed by two deadlines and an exam this week.',
        historySummary: '',
        selectedLabelKey: 'planning',
        recommendedSkillId: 'workflow.plan_next_steps',
        templateId: 'template.plan_next_steps',
        profileLabelKeys: ['academic_planning', 'stress_sensitive'],
        recentLabelKeys: [],
        imageCount: 0,
      ),
    );

    expect(response.text, contains('Here is a calm plan.'));
    expect(response.trace.usedLocalModel, isTrue);
    expect(
      response.trace.activatedRoles,
      containsAll([
        OrbitAgentRole.workflowController,
        OrbitAgentRole.academicPlanning,
        OrbitAgentRole.stressMonitoring,
        OrbitAgentRole.synthesizer,
      ]),
    );
  });

  test('falls back deterministically when the local model is unavailable',
      () async {
    final orchestrator = OrbitAgentOrchestrator(
      llmClient: _FailingLocalLlmClient(),
    );

    final response = await orchestrator.respond(
      const OrbitAgentRequest(
        message: 'Help me plan study blocks for my quiz.',
        historySummary: '',
        selectedLabelKey: 'study_help',
        recommendedSkillId: null,
        templateId: null,
        profileLabelKeys: [],
        recentLabelKeys: [],
        imageCount: 0,
      ),
    );

    expect(response.trace.usedLocalModel, isFalse);
    expect(response.trace.fallbackReason, isNotNull);
    expect(response.text, contains('local ORBIT workflow'));
    expect(response.text, contains('Academic planning'));
  });

  test('builds adaptive skill tool priority from labels and task metadata',
      () async {
    final orchestrator = OrbitAgentOrchestrator(
      llmClient: const _FakeLocalLlmClient('Try a vegan lunch near campus.'),
    );

    final response = await orchestrator.respond(
      const OrbitAgentRequest(
        message: 'Find food near campus before class.',
        historySummary: '',
        selectedLabelKey: 'life_logistics',
        recommendedSkillId: 'workflow.find_student_place',
        templateId: 'template.food_near_campus',
        profileLabelKeys: ['vegan'],
        recentLabelKeys: [],
        imageCount: 0,
      ),
    );

    final adaptiveSkill = response.trace.skillResults.first;
    expect(adaptiveSkill.title, 'Adaptive runtime skill');
    expect(
      adaptiveSkill.recommendations.join('\n'),
      contains('live_places_search'),
    );
  });
}

class _FakeLocalLlmClient implements LocalLlmClient {
  const _FakeLocalLlmClient(this.text);

  final String text;

  @override
  Future<LocalLlmResult> generate(LocalLlmRequest request) async {
    return LocalLlmResult(
      text: text,
      model: LocalLlmConfig.defaultModel,
      provider: 'test',
    );
  }
}

class _FailingLocalLlmClient implements LocalLlmClient {
  @override
  Future<LocalLlmResult> generate(LocalLlmRequest request) {
    throw const LocalLlmException('Ollama is not running');
  }
}
