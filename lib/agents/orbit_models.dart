enum OrbitAgentRole {
  workflowController,
  academicPlanning,
  stressMonitoring,
  campusResources,
  careerStrategy,
  lifeLogistics,
  synthesizer,
}

extension OrbitAgentRolePresentation on OrbitAgentRole {
  String get label => switch (this) {
        OrbitAgentRole.workflowController => 'Workflow controller',
        OrbitAgentRole.academicPlanning => 'Academic planning',
        OrbitAgentRole.stressMonitoring => 'Stress monitoring',
        OrbitAgentRole.campusResources => 'Campus resources',
        OrbitAgentRole.careerStrategy => 'Career strategy',
        OrbitAgentRole.lifeLogistics => 'Life logistics',
        OrbitAgentRole.synthesizer => 'Response synthesizer',
      };
}

class OrbitAgentRequest {
  const OrbitAgentRequest({
    required this.message,
    required this.historySummary,
    required this.selectedLabelKey,
    required this.recommendedSkillId,
    required this.templateId,
    required this.profileLabelKeys,
    required this.recentLabelKeys,
    required this.imageCount,
    this.externalContextSummary = '',
    this.externalLabelKeys = const [],
    this.externalStressScore,
  });

  final String message;
  final String historySummary;
  final String? selectedLabelKey;
  final String? recommendedSkillId;
  final String? templateId;
  final List<String> profileLabelKeys;
  final List<String> recentLabelKeys;
  final int imageCount;
  final String externalContextSummary;
  final List<String> externalLabelKeys;
  final double? externalStressScore;

  bool get hasImages => imageCount > 0;
}

class StudentContext {
  StudentContext({
    required Iterable<String> profileLabelKeys,
    required Iterable<String> recentLabelKeys,
    required Iterable<String> externalLabelKeys,
    required this.selectedLabelKey,
    required this.recommendedSkillId,
    required this.templateId,
    required this.historySummary,
    required this.externalContextSummary,
    required this.externalStressScore,
    required this.hasImages,
    required this.message,
  })  : profileLabelKeys = _normalized(profileLabelKeys),
        recentLabelKeys = _normalized(recentLabelKeys),
        externalLabelKeys = _normalized(externalLabelKeys);

  static const List<String> assumedOnboardingLabels = [
    'college_student',
    'academic_planning',
    'stress_sensitive',
    'career_builder',
    'life_logistics',
    'local_first',
  ];

  final List<String> profileLabelKeys;
  final List<String> recentLabelKeys;
  final List<String> externalLabelKeys;
  final String? selectedLabelKey;
  final String? recommendedSkillId;
  final String? templateId;
  final String historySummary;
  final String externalContextSummary;
  final double? externalStressScore;
  final bool hasImages;
  final String message;

  List<String> get allLabels {
    final labels = <String>{
      ...assumedOnboardingLabels,
      ...profileLabelKeys,
      ...recentLabelKeys,
      ...externalLabelKeys,
      if (selectedLabelKey != null && selectedLabelKey!.trim().isNotEmpty)
        selectedLabelKey!.trim(),
      ..._labelsFromMessage(message),
    };
    return labels.toList(growable: false)..sort();
  }

  bool hasAnyLabel(Iterable<String> labels) {
    final current = allLabels.toSet();
    return labels.any(current.contains);
  }

  double get stressEstimate {
    final externalScore = externalStressScore;
    if (externalScore != null) {
      return externalScore.clamp(0.0, 1.0);
    }

    final text = message.toLowerCase();
    var score = 0.18;
    for (final keyword in const [
      'stress',
      'stressed',
      'overwhelmed',
      'burnout',
      'anxious',
      'panic',
      'exhausted',
      'behind',
      'deadline',
      'exam',
      'midterm',
      'final',
    ]) {
      if (text.contains(keyword)) {
        score += 0.08;
      }
    }
    if (hasAnyLabel(const ['wellbeing_checkin', 'stress_sensitive'])) {
      score += 0.1;
    }
    if (recentLabelKeys.contains('wellbeing_checkin')) {
      score += 0.08;
    }
    return score.clamp(0.0, 0.92);
  }

  String get stressBand {
    final value = stressEstimate;
    if (value >= 0.68) {
      return 'elevated';
    }
    if (value >= 0.42) {
      return 'moderate';
    }
    return 'baseline';
  }

  String get summaryForPrompt {
    return [
      'Labels: ${allLabels.join(', ')}',
      if (selectedLabelKey != null) 'Selected focus: $selectedLabelKey',
      if (recommendedSkillId != null) 'Recommended skill: $recommendedSkillId',
      if (templateId != null) 'Template: $templateId',
      'Stress estimate: $stressBand (${stressEstimate.toStringAsFixed(2)})',
      if (hasImages) 'Attached images: present, but text-only local model',
      if (historySummary.trim().isNotEmpty) 'Recent chat: $historySummary',
      if (externalContextSummary.trim().isNotEmpty)
        'Real data context: $externalContextSummary',
    ].join('\n');
  }

  static List<String> _normalized(Iterable<String> labels) {
    return labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static List<String> _labelsFromMessage(String message) {
    final text = message.toLowerCase();
    final labels = <String>[];

    if (_containsAny(text, const ['deadline', 'assignment', 'exam', 'study'])) {
      labels.add('academic_planning');
    }
    if (_containsAny(text, const [
      'course',
      'courses',
      'class',
      'classes',
      'professor',
      'teacher',
      'semester',
      'schedule',
      'registration',
      'testudo',
    ])) {
      labels.add('course_selection');
      labels.add('semester_planning');
    }
    if (_containsAny(text, const ['internship', 'resume', 'career'])) {
      labels.add('career_builder');
    }
    if (_containsAny(text, const ['budget', 'rent', 'meal', 'housing'])) {
      labels.add('life_logistics');
    }
    if (_containsAny(text, const ['campus', 'resource', 'office', 'advisor'])) {
      labels.add('campus_resources');
    }
    if (_containsAny(text, const ['stress', 'overwhelmed', 'anxious'])) {
      labels.add('wellbeing_checkin');
    }

    return labels;
  }

  static bool _containsAny(String text, Iterable<String> keywords) {
    return keywords.any(text.contains);
  }
}

enum OrbitToolPermissionLevel {
  autoAllowed,
  approvalRequired,
  blocked,
}

extension OrbitToolPermissionLevelPresentation on OrbitToolPermissionLevel {
  String get label => switch (this) {
        OrbitToolPermissionLevel.autoAllowed => 'auto allowed',
        OrbitToolPermissionLevel.approvalRequired => 'requires approval',
        OrbitToolPermissionLevel.blocked => 'blocked',
      };
}

class ToolPermissionDecision {
  const ToolPermissionDecision({
    required this.toolId,
    required this.level,
    required this.reason,
  });

  final String toolId;
  final OrbitToolPermissionLevel level;
  final String reason;

  String get summary => '$toolId: ${level.label} - $reason';
}

class OrbitToolPermissionPolicy {
  const OrbitToolPermissionPolicy();

  List<ToolPermissionDecision> classify({
    required Iterable<String> toolIds,
    required StudentContext context,
  }) {
    final uniqueTools = toolIds.toSet().toList(growable: false)..sort();
    return uniqueTools
        .map((toolId) => _classifyOne(toolId: toolId, context: context))
        .toList(growable: false);
  }

  ToolPermissionDecision _classifyOne({
    required String toolId,
    required StudentContext context,
  }) {
    if (_blockedTools.contains(toolId) ||
        toolId.startsWith('send_') ||
        toolId.startsWith('submit_') ||
        toolId.startsWith('delete_') ||
        toolId.startsWith('pay_')) {
      return ToolPermissionDecision(
        toolId: toolId,
        level: OrbitToolPermissionLevel.blocked,
        reason:
            'This demo can advise, but it cannot take irreversible action for a student.',
      );
    }

    if (_approvalRequiredTools.contains(toolId)) {
      return ToolPermissionDecision(
        toolId: toolId,
        level: OrbitToolPermissionLevel.approvalRequired,
        reason:
            'This may touch connected account, campus, calendar, route, or location data.',
      );
    }

    if (toolId == 'recovery_planner' && context.stressBand == 'elevated') {
      return const ToolPermissionDecision(
        toolId: 'recovery_planner',
        level: OrbitToolPermissionLevel.autoAllowed,
        reason:
            'Low-risk wellbeing guidance is allowed when stress signals are elevated.',
      );
    }

    return ToolPermissionDecision(
      toolId: toolId,
      level: OrbitToolPermissionLevel.autoAllowed,
      reason:
          'This is a low-risk local reasoning tool and does not write to outside services.',
    );
  }

  static const Set<String> _approvalRequiredTools = {
    'calendar_signal_review',
    'campus_route_planner',
    'canvas_course_scan',
    'course_professor_planner',
    'live_places_search',
    'schedule_builder',
  };

  static const Set<String> _blockedTools = {
    'book_appointment',
    'cancel_class',
    'message_advisor',
    'submit_assignment',
  };
}

class SkillResult {
  const SkillResult({
    required this.skillId,
    required this.role,
    required this.title,
    required this.summary,
    required this.recommendations,
    required this.confidence,
    this.toolPermissions = const [],
  });

  final String skillId;
  final OrbitAgentRole role;
  final String title;
  final String summary;
  final List<String> recommendations;
  final double confidence;
  final List<ToolPermissionDecision> toolPermissions;

  String get asPromptBlock {
    final bulletText = recommendations.map((item) => '- $item').join('\n');
    final permissionText =
        toolPermissions.map((item) => '- ${item.summary}').join('\n');
    return [
      '${role.label} / $title',
      'Confidence: ${confidence.toStringAsFixed(2)}',
      summary,
      if (bulletText.isNotEmpty) bulletText,
      if (permissionText.isNotEmpty) 'Tool permission policy:\n$permissionText',
    ].join('\n');
  }
}

class OrbitAgentTrace {
  const OrbitAgentTrace({
    required this.activatedRoles,
    required this.skillResults,
    required this.usedLocalModel,
    required this.modelName,
    required this.fallbackReason,
  });

  final List<OrbitAgentRole> activatedRoles;
  final List<SkillResult> skillResults;
  final bool usedLocalModel;
  final String modelName;
  final String? fallbackReason;
}

class OrbitAgentResponse {
  const OrbitAgentResponse({
    required this.text,
    required this.trace,
  });

  final String text;
  final OrbitAgentTrace trace;
}
