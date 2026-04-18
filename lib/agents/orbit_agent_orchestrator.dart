import 'package:chatbotapp/agents/local_llm_client.dart';
import 'package:chatbotapp/agents/orbit_agents.dart';
import 'package:chatbotapp/agents/orbit_models.dart';

class OrbitAgentOrchestrator {
  OrbitAgentOrchestrator({
    LocalLlmClient? llmClient,
    List<OrbitAgent>? agents,
  })  : _llmClient = llmClient ?? OllamaLocalLlmClient(),
        _agents = agents ??
            const [
              AcademicPlanningAgent(),
              StressMonitoringAgent(),
              CampusResourceAgent(),
              CareerStrategyAgent(),
              LifeLogisticsAgent(),
            ];

  final LocalLlmClient _llmClient;
  final List<OrbitAgent> _agents;
  static const OrbitToolPermissionPolicy _toolPermissionPolicy =
      OrbitToolPermissionPolicy();

  Future<OrbitAgentResponse> respond(OrbitAgentRequest request) async {
    final context = StudentContext(
      profileLabelKeys: request.profileLabelKeys,
      recentLabelKeys: request.recentLabelKeys,
      externalLabelKeys: request.externalLabelKeys,
      selectedLabelKey: request.selectedLabelKey,
      recommendedSkillId: request.recommendedSkillId,
      templateId: request.templateId,
      historySummary: request.historySummary,
      externalContextSummary: request.externalContextSummary,
      externalStressScore: request.externalStressScore,
      hasImages: request.hasImages,
      message: request.message,
    );

    final activated = _selectAgents(context);
    final skillResults = [
      _buildAdaptiveSkill(request: request, context: context),
      ...activated
          .map((agent) => agent.run(request: request, context: context)),
    ];

    try {
      final localResult = await _llmClient.generate(
        LocalLlmRequest(
          systemPrompt: _systemPrompt,
          prompt: _synthesisPrompt(
            request: request,
            context: context,
            skillResults: skillResults,
          ),
          temperature: 0.28,
          maxTokens: 850,
        ),
      );

      return OrbitAgentResponse(
        text: _appendTraceFooter(
          text: localResult.text,
          skillResults: skillResults,
          modelName: localResult.model,
          usedLocalModel: true,
        ),
        trace: OrbitAgentTrace(
          activatedRoles: _rolesFor(skillResults),
          skillResults: skillResults,
          usedLocalModel: true,
          modelName: localResult.model,
          fallbackReason: null,
        ),
      );
    } catch (error) {
      final fallback = _deterministicFallback(
        request: request,
        context: context,
        skillResults: skillResults,
        reason: error.toString(),
      );
      return OrbitAgentResponse(
        text: fallback,
        trace: OrbitAgentTrace(
          activatedRoles: _rolesFor(skillResults),
          skillResults: skillResults,
          usedLocalModel: false,
          modelName: LocalLlmConfig.fromEnvironment().model,
          fallbackReason: error.toString(),
        ),
      );
    }
  }

  List<OrbitAgent> _selectAgents(StudentContext context) {
    final selected = _agents
        .where((agent) => agent.shouldActivate(context))
        .take(4)
        .toList(growable: false);

    if (selected.isNotEmpty) {
      return selected;
    }

    return const [
      AcademicPlanningAgent(),
      StressMonitoringAgent(),
      CampusResourceAgent(),
    ];
  }

  List<OrbitAgentRole> _rolesFor(List<SkillResult> skillResults) {
    return [
      OrbitAgentRole.workflowController,
      ...skillResults.map((result) => result.role),
      OrbitAgentRole.synthesizer,
    ];
  }

  SkillResult _buildAdaptiveSkill({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    final labels = context.allLabels;
    const livePlaceLabels = {
      'life_logistics',
      'vegan',
      'diet_vegan',
      'plant_based',
      'vegetarian',
      'diet_vegetarian',
      'halal',
      'kosher',
      'gluten_free',
      'food_allergy',
      'commuter',
    };
    final needsLivePlaces =
        labels.any((label) => livePlaceLabels.contains(label));
    final needsCoursePlanning = labels.contains('course_selection') ||
        labels.contains('semester_planning') ||
        RegExp(
          r'\b(course|courses|class|classes|professor|semester|registration|testudo|planetterp)\b',
        ).hasMatch(request.message.toLowerCase());
    final tools = {
      'chat_history_lookup',
      if (labels.contains('planning') || labels.contains('academic_planning'))
        'schedule_builder',
      if (needsCoursePlanning) 'course_professor_planner',
      if (labels.contains('study_help')) 'canvas_course_scan',
      if (labels.contains('wellbeing_checkin') ||
          labels.contains('stress_sensitive'))
        'stress_report_summarizer',
      if (needsLivePlaces) 'live_places_search',
      if (labels.contains('campus_navigation')) 'campus_route_planner',
      if (labels.contains('career_builder')) 'career_timeline_builder',
    }.toList(growable: false);
    final toolPermissions = _toolPermissionPolicy.classify(
      toolIds: tools,
      context: context,
    );

    return SkillResult(
      skillId:
          'runtime.skill.${request.selectedLabelKey ?? 'auto'}.${request.templateId ?? 'direct'}',
      role: OrbitAgentRole.workflowController,
      title: 'Adaptive runtime skill',
      summary:
          'Generated from the current task, profile labels, recent labels, imported signals, and selected template metadata. This skill updates role priority and tool order before synthesis.',
      recommendations: [
        'Primary labels: ${labels.take(8).join(', ')}',
        if (request.recommendedSkillId != null)
          'Use routed skill hint: ${request.recommendedSkillId}',
        if (request.templateId != null)
          'Use template hint: ${request.templateId}',
        'Tool priority: ${tools.isEmpty ? 'none' : tools.join(' -> ')}',
        if (toolPermissions.isNotEmpty)
          'Tool permissions: ${toolPermissions.map((item) => '${item.toolId} ${item.level.label}').join(', ')}',
        'Prompt policy: answer the student request directly, but invoke or reference tools only when the structured context supports them.',
      ],
      confidence: 0.9,
      toolPermissions: toolPermissions,
    );
  }

  String _synthesisPrompt({
    required OrbitAgentRequest request,
    required StudentContext context,
    required List<SkillResult> skillResults,
  }) {
    final skillBlocks =
        skillResults.map((result) => result.asPromptBlock).join('\n\n---\n\n');

    return '''
User request:
${request.message}

Student state:
${context.summaryForPrompt}

Activated agent skill outputs:
$skillBlocks

Write the final response for the student. Be specific, calm, and concise.
Use the activated skill outputs as constraints, not as content to expose verbatim.
If data from Canvas, Google Calendar, campus resources, or datasets is missing, say what is needed instead of fabricating it.
''';
  }

  String _deterministicFallback({
    required OrbitAgentRequest request,
    required StudentContext context,
    required List<SkillResult> skillResults,
    required String reason,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('I can help with this using the local ORBIT workflow.');
    if (request.hasImages) {
      buffer.writeln(
        '\nI noticed an image attachment. This build is using a text-only local model path, so describe the image if you want image-specific reasoning.',
      );
    }
    buffer.writeln('\nHere is the best next step:');

    final firstRecommendation = skillResults
        .expand((result) => result.recommendations)
        .cast<String?>()
        .firstWhere((item) => item != null, orElse: () => null);

    buffer.writeln(
      '- ${firstRecommendation ?? 'Tell me the goal, deadline, and the constraint that is making this hard.'}',
    );

    if (context.stressBand != 'baseline') {
      buffer.writeln(
        '- Because the stress signal looks ${context.stressBand}, keep the first action small enough to finish in 10-20 minutes.',
      );
    }

    buffer.writeln('\nAgent notes:');
    for (final result in skillResults) {
      buffer.writeln('- ${result.role.label}: ${result.summary}');
    }

    buffer.writeln(
      '\nLocal model note: I could not reach the configured model, so this response used deterministic agent logic. Start Ollama with `${LocalLlmConfig.fromEnvironment().model}` for richer local synthesis.',
    );
    return buffer.toString().trim();
  }

  String _appendTraceFooter({
    required String text,
    required List<SkillResult> skillResults,
    required String modelName,
    required bool usedLocalModel,
  }) {
    final roles =
        _rolesFor(skillResults).map((role) => role.label).join(' -> ');
    final modelStatus =
        usedLocalModel ? 'local model: $modelName' : 'local fallback';
    return [
      text.trim(),
      '',
      'ORBIT trace: $roles ($modelStatus)',
    ].join('\n');
  }

  static const String _systemPrompt = '''
You are ORBIT, a label-driven, skill-compositional multi-role agent for student academic support and well-being.
You run locally on a lightweight model, so be efficient and structured.

Operating rules:
- Use workflow-controller thinking: understand the request, apply only relevant agent skills, then synthesize.
- Respect the supplied labels, recent history, and stress estimate as personalization signals.
- Do not claim access to live Canvas, Google Calendar, campus resources, datasets, or sensors unless their data is present in the prompt.
- Do not diagnose medical or mental health conditions. If immediate safety risk appears, advise emergency or campus crisis support.
- Give one concrete next action before broad strategy.
- Keep the response helpful for a student on low time and low energy.
''';
}
