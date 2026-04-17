import 'package:chatbotapp/models/prompt_recommendation.dart';

enum StressBand {
  steady,
  elevated,
  high,
}

extension StressBandPresentation on StressBand {
  String get displayName => switch (this) {
        StressBand.steady => 'Steady',
        StressBand.elevated => 'Elevated',
        StressBand.high => 'High',
      };
}

class StressReport {
  const StressReport({
    required this.band,
    required this.score,
    required this.summary,
    required this.drivers,
    required this.sourceBadges,
  });

  final StressBand band;
  final double score;
  final String summary;
  final List<String> drivers;
  final List<String> sourceBadges;
}

class SupportPromptAction {
  const SupportPromptAction({
    required this.title,
    required this.detail,
    required this.prompt,
    required this.label,
  });

  final String title;
  final String detail;
  final String prompt;
  final SupportLabel label;
}

class AgentToolSuggestion {
  const AgentToolSuggestion({
    required this.toolId,
    required this.label,
    required this.reason,
  });

  final String toolId;
  final String label;
  final String reason;
}

class AgentSkillBlueprint {
  const AgentSkillBlueprint({
    required this.skillId,
    required this.title,
    required this.summary,
    required this.systemPrompt,
    required this.starterPrompt,
    required this.tools,
  });

  final String skillId;
  final String title;
  final String summary;
  final String systemPrompt;
  final String starterPrompt;
  final List<AgentToolSuggestion> tools;

  String toMarkdown() {
    final toolLines = tools
        .map((tool) => '- `${tool.toolId}`: ${tool.reason}')
        .join('\n');
    return '''
# $title

## Skill ID
`$skillId`

## Summary
$summary

## System Prompt
$systemPrompt

## Recommended Tools
$toolLines

## Starter Prompt
$starterPrompt
''';
  }
}

class SupportIntelligenceBundle {
  const SupportIntelligenceBundle({
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.stressReport,
    required this.questions,
    required this.suggestions,
    required this.skill,
  });

  final SupportLabel primaryLabel;
  final SupportLabel secondaryLabel;
  final StressReport stressReport;
  final List<SupportPromptAction> questions;
  final List<SupportPromptAction> suggestions;
  final AgentSkillBlueprint skill;
}
