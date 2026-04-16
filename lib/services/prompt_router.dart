import 'package:chatbotapp/models/prompt_recommendation.dart';

class PromptRouter {
  const PromptRouter();

  static const _defaultReason = 'Good place to start';
  static const _placeholderReason = 'Try this';

  static const List<_TemplateDefinition> _catalog = [
    _TemplateDefinition(
      label: SupportLabel.planning,
      templateId: 'template.plan_next_steps',
      skillId: 'workflow.plan_next_steps',
      title: 'Map out a plan',
      description: 'Break a goal into steps, priorities, and deadlines.',
      promptTemplate: 'Help me make a step-by-step plan for: ',
      keywords: ['plan', 'schedule', 'roadmap', 'organize', 'todo', 'day'],
      isDefault: true,
    ),
    _TemplateDefinition(
      label: SupportLabel.writing,
      templateId: 'template.draft_polished_reply',
      skillId: 'workflow.draft_polished_reply',
      title: 'Draft a polished reply',
      description: 'Turn rough thoughts into a clear, polished message.',
      promptTemplate: 'Help me draft a clear, polished message about: ',
      keywords: ['reply', 'email', 'message', 'draft', 'write', 'respond'],
      isDefault: true,
    ),
    _TemplateDefinition(
      label: SupportLabel.studyHelp,
      templateId: 'template.study_coach',
      skillId: 'workflow.study_coach',
      title: 'Study this with me',
      description: 'Learn a concept step by step with quick checks.',
      promptTemplate:
          'Teach me this concept step by step and quiz me at the end: ',
      keywords: ['study', 'homework', 'quiz', 'exam', 'concept', 'understand'],
      isDefault: true,
    ),
    _TemplateDefinition(
      label: SupportLabel.summarization,
      templateId: 'template.summarize_clearly',
      skillId: 'workflow.summarize_clearly',
      title: 'Summarize and simplify',
      description: 'Condense information into key takeaways.',
      promptTemplate:
          'Summarize this in plain language and highlight the key takeaways: ',
      keywords: ['summarize', 'summary', 'recap', 'brief', 'tl;dr'],
      isDefault: false,
    ),
    _TemplateDefinition(
      label: SupportLabel.imageAnalysis,
      templateId: 'template.analyze_image',
      skillId: 'workflow.analyze_image',
      title: 'Analyze an image',
      description: 'Describe what is visible and explain what matters.',
      promptTemplate:
          'Describe what is visible in this image and explain anything important or unusual.',
      keywords: ['image', 'photo', 'picture', 'screenshot', 'diagram'],
      isDefault: false,
    ),
    _TemplateDefinition(
      label: SupportLabel.wellbeingCheckIn,
      templateId: 'template.wellbeing_checkin',
      skillId: 'workflow.wellbeing_checkin',
      title: 'Reflect and regroup',
      description: 'Turn overwhelm into one concrete next step.',
      promptTemplate:
          'Help me check in, organize what feels overwhelming, and suggest one next step.',
      keywords: ['stress', 'stressed', 'anxious', 'overwhelmed', 'burnout'],
      isDefault: false,
    ),
  ];

  List<SupportLabel> get labels => SupportLabel.values;

  List<PromptRecommendation> recommend({
    required RoutingContext context,
    int limit = 3,
  }) {
    final trimmedDraft = context.trimmedDraftText.toLowerCase();
    final scored = _catalog
        .map((template) => _scoreTemplate(template, context, trimmedDraft))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final strongMatches = scored.where((item) => item.score >= 40).toList();
    if (strongMatches.isNotEmpty) {
      return scored.take(limit).toList(growable: false);
    }

    final fallbackMatches = scored.where((item) => item.score > 0).toList();
    if (fallbackMatches.isNotEmpty) {
      return fallbackMatches.take(limit).toList(growable: false);
    }

    return _catalog
        .where((template) => template.isDefault)
        .take(limit)
        .map(
          (template) => PromptRecommendation(
            label: template.label,
            templateId: template.templateId,
            skillId: template.skillId,
            title: template.title,
            description: template.description,
            promptTemplate: template.promptTemplate,
            reason: _defaultReason,
            score: 10,
          ),
        )
        .toList(growable: false);
  }

  PromptRecommendation _scoreTemplate(
    _TemplateDefinition template,
    RoutingContext context,
    String trimmedDraft,
  ) {
    var score = template.isDefault ? 10 : 0;
    var reason = template.isDefault ? _defaultReason : _placeholderReason;

    if (context.selectedLabel == template.label) {
      score += 160;
      reason = 'Based on your selected label';
    }

    if (context.hasImages && template.label == SupportLabel.imageAnalysis) {
      score += 150;
      reason = 'Because you attached an image';
    }

    final keywordMatches = template.keywords
        .where((keyword) => trimmedDraft.contains(keyword))
        .length;
    if (keywordMatches > 0) {
      score += 80 + (keywordMatches * 8);
      reason = 'Based on your draft';
    }

    if (context.recentLabels.contains(template.label)) {
      score += 18;
      if (_canReplaceFallbackReason(reason)) {
        reason = 'Inspired by recent chats';
      }
    }

    if (context.preferredLabels.contains(template.label)) {
      score += _preferredLabelBoost(context, template.label);
      if (_canReplaceFallbackReason(reason)) {
        reason = 'Matched from your saved setup';
      }
    }

    return PromptRecommendation(
      label: template.label,
      templateId: template.templateId,
      skillId: template.skillId,
      title: template.title,
      description: template.description,
      promptTemplate: template.promptTemplate,
      reason: reason,
      score: score,
    );
  }

  bool _canReplaceFallbackReason(String reason) {
    return reason == _defaultReason || reason == _placeholderReason;
  }

  int _preferredLabelBoost(RoutingContext context, SupportLabel label) {
    final index = context.preferredLabels.indexOf(label);
    if (index < 0) {
      return 0;
    }

    return switch (index) {
      0 => 36,
      1 => 24,
      2 => 18,
      3 => 12,
      _ => 6,
    };
  }
}

class _TemplateDefinition {
  const _TemplateDefinition({
    required this.label,
    required this.templateId,
    required this.skillId,
    required this.title,
    required this.description,
    required this.promptTemplate,
    required this.keywords,
    required this.isDefault,
  });

  final SupportLabel label;
  final String templateId;
  final String skillId;
  final String title;
  final String description;
  final String promptTemplate;
  final List<String> keywords;
  final bool isDefault;
}
