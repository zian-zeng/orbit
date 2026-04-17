import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/models/support_intelligence.dart';

class SupportIntelligenceService {
  const SupportIntelligenceService();

  static const _stressKeywords = <String, double>{
    'overwhelmed': 0.18,
    'stress': 0.16,
    'stressed': 0.16,
    'burnout': 0.18,
    'anxious': 0.18,
    'deadline': 0.12,
    'deadlines': 0.12,
    'exam': 0.12,
    'behind': 0.1,
    'midterm': 0.1,
    'final': 0.08,
    'pressure': 0.1,
    'sleep': 0.08,
  };

  SupportIntelligenceBundle? buildBundle({
    required List<String> routingLabelKeys,
    required List<String> recentLabelKeys,
    required List<String> labelSignalSources,
    required Iterable<ChatHistory> history,
  }) {
    final routingLabels = supportLabelsFromKeys(routingLabelKeys);
    if (routingLabels.isEmpty) {
      return null;
    }

    final recentLabels = supportLabelsFromKeys(recentLabelKeys);
    final orderedHistory = history.toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final primaryLabel = routingLabels.first;
    final secondaryLabel =
        routingLabels.length > 1 ? routingLabels[1] : routingLabels.first;
    final stressReport = _buildStressReport(
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      recentLabels: recentLabels,
      signalSources: labelSignalSources,
      history: orderedHistory,
    );

    return SupportIntelligenceBundle(
      primaryLabel: primaryLabel,
      secondaryLabel: secondaryLabel,
      stressReport: stressReport,
      questions: _buildQuestions(
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        stressReport: stressReport,
        signalSources: labelSignalSources,
      ),
      suggestions: _buildSuggestions(
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        stressReport: stressReport,
      ),
      skill: _buildSkillBlueprint(
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        stressReport: stressReport,
        signalSources: labelSignalSources,
      ),
    );
  }

  StressReport _buildStressReport({
    required SupportLabel primaryLabel,
    required SupportLabel secondaryLabel,
    required List<SupportLabel> recentLabels,
    required List<String> signalSources,
    required List<ChatHistory> history,
  }) {
    var score = 0.16;
    final drivers = <String>[];

    if (primaryLabel == SupportLabel.wellbeingCheckIn) {
      score += 0.22;
      drivers.add('wellbeing-first routing');
    }
    if (secondaryLabel == SupportLabel.wellbeingCheckIn) {
      score += 0.08;
      drivers.add('wellbeing backup route');
    }
    if (primaryLabel == SupportLabel.planning &&
        signalSources.any((source) => source.contains('Google Calendar'))) {
      score += 0.08;
      drivers.add('calendar workload pressure');
    }
    if (primaryLabel == SupportLabel.studyHelp &&
        signalSources.any((source) => source.contains('Canvas'))) {
      score += 0.08;
      drivers.add('course workload pressure');
    }

    for (final label in recentLabels.take(3)) {
      if (label == SupportLabel.wellbeingCheckIn) {
        score += 0.08;
      } else if (label == SupportLabel.planning ||
          label == SupportLabel.studyHelp) {
        score += 0.04;
      }
    }

    final historyText = history
        .take(6)
        .map((chat) => '${chat.prompt} ${chat.response}'.toLowerCase())
        .join(' ');
    for (final entry in _stressKeywords.entries) {
      if (historyText.contains(entry.key)) {
        score += entry.value;
        drivers.add(entry.key);
      }
    }

    if (signalSources.contains('Google Calendar')) {
      score += 0.08;
    }
    if (signalSources.contains('Canvas')) {
      score += 0.08;
    }

    final clampedScore = score.clamp(0.0, 1.0).toDouble();
    final band = clampedScore >= 0.68
        ? StressBand.high
        : clampedScore >= 0.38
            ? StressBand.elevated
            : StressBand.steady;

    final summary = switch (band) {
      StressBand.high =>
        'Pressure signals are stacking up. Lead with a clarifying question and a narrow next step.',
      StressBand.elevated =>
        'Workload looks manageable but crowded. Keep suggestions concrete and time-bounded.',
      StressBand.steady =>
        'Signals are stable. Lead with lightweight guidance and one proactive check-in.',
    };

    final sourceBadges = {
      if (signalSources.isNotEmpty) ...signalSources.take(3),
      if (history.isNotEmpty) 'History',
    }.toList(growable: false);

    return StressReport(
      band: band,
      score: clampedScore,
      summary: summary,
      drivers: drivers.take(4).toList(growable: false),
      sourceBadges: sourceBadges,
    );
  }

  List<SupportPromptAction> _buildQuestions({
    required SupportLabel primaryLabel,
    required SupportLabel secondaryLabel,
    required StressReport stressReport,
    required List<String> signalSources,
  }) {
    final prompts = <SupportPromptAction>[
      _promptForLabel(
        label: primaryLabel,
        stressReport: stressReport,
        isQuestion: true,
      ),
    ];

    if (signalSources.contains('Canvas')) {
      prompts.add(
        const SupportPromptAction(
          title: 'Course friction',
          detail:
              'Use imported course activity to find the most fragile class.',
          prompt:
              'Use my current course activity to identify the class or assignment that is most at risk, then ask me one clarifying question before suggesting the next move.',
          label: SupportLabel.studyHelp,
        ),
      );
    } else if (signalSources.contains('Google Calendar')) {
      prompts.add(
        const SupportPromptAction(
          title: 'Calendar pressure',
          detail: 'Use imported schedule signals to narrow the next question.',
          prompt:
              'Look at my upcoming schedule pressure and ask me the one question that would most improve my plan for the next two days.',
          label: SupportLabel.planning,
        ),
      );
    } else {
      prompts.add(
        _promptForLabel(
          label: secondaryLabel,
          stressReport: stressReport,
          isQuestion: true,
        ),
      );
    }

    return prompts;
  }

  List<SupportPromptAction> _buildSuggestions({
    required SupportLabel primaryLabel,
    required SupportLabel secondaryLabel,
    required StressReport stressReport,
  }) {
    return [
      _promptForLabel(
        label: primaryLabel,
        stressReport: stressReport,
        isQuestion: false,
      ),
      _promptForLabel(
        label: secondaryLabel,
        stressReport: stressReport,
        isQuestion: false,
      ),
    ];
  }

  SupportPromptAction _promptForLabel({
    required SupportLabel label,
    required StressReport stressReport,
    required bool isQuestion,
  }) {
    final highStress = stressReport.band == StressBand.high;
    return switch (label) {
      SupportLabel.planning => SupportPromptAction(
          title: isQuestion ? 'Stabilize the week' : 'Build a rescue plan',
          detail: isQuestion
              ? 'Ask the one planning question that reduces deadline risk.'
              : 'Turn workload into a concrete 48-hour plan.',
          prompt: highStress
              ? 'Help me identify the deadline or obligation most likely to slip this week, ask one clarifying question, and then build a 48-hour rescue plan.'
              : 'Help me map my next two days into a simple plan with the most important task first.',
          label: label,
        ),
      SupportLabel.writing => SupportPromptAction(
          title: isQuestion ? 'Unblock the draft' : 'Draft the next message',
          detail: isQuestion
              ? 'Find the exact piece of writing that is stuck.'
              : 'Move one written deliverable forward.',
          prompt: isQuestion
              ? 'Ask me what piece of writing or message feels most blocked right now, then help me break it into a small next action.'
              : 'Help me draft the next message, reflection, or written deliverable that is creating friction.',
          label: label,
        ),
      SupportLabel.studyHelp => SupportPromptAction(
          title:
              isQuestion ? 'Pinpoint the class issue' : 'Study with structure',
          detail: isQuestion
              ? 'Narrow the exact concept, quiz, or assignment at risk.'
              : 'Convert the hardest course work into a guided study plan.',
          prompt: isQuestion
              ? 'Ask me which course, concept, quiz, or assignment feels least under control, then help me decide how to study it.'
              : 'Help me turn my current course pressure into a step-by-step study plan with one checkpoint at the end.',
          label: label,
        ),
      SupportLabel.summarization => SupportPromptAction(
          title: isQuestion
              ? 'Reduce information overload'
              : 'Condense the next input',
          detail: isQuestion
              ? 'Find the reading, notes, or information load that needs compression.'
              : 'Summarize the highest-friction content into takeaways.',
          prompt: isQuestion
              ? 'Ask me what reading, notes, or instructions feel too dense right now, then help me pull out the key takeaways.'
              : 'Summarize the information I am struggling with into the few points I need to act on next.',
          label: label,
        ),
      SupportLabel.imageAnalysis => SupportPromptAction(
          title: isQuestion
              ? 'Inspect the visual blocker'
              : 'Explain the screenshot',
          detail: isQuestion
              ? 'Find the screenshot, slide, or diagram that needs decoding.'
              : 'Use visual interpretation to clear the next blocker.',
          prompt: isQuestion
              ? 'Ask me which screenshot, diagram, slide, or visual is blocking me, then explain what matters in it.'
              : 'Help me analyze the next screenshot or diagram that is keeping me from moving forward.',
          label: label,
        ),
      SupportLabel.wellbeingCheckIn => SupportPromptAction(
          title: isQuestion ? 'Check the pressure point' : 'Reset the workload',
          detail: isQuestion
              ? 'Find the signal that is making everything feel heavier.'
              : 'Turn overload into one calmer next step.',
          prompt: highStress
              ? 'Ask me what is making this feel most overwhelming right now, then help me pick one low-friction next step and one recovery action.'
              : 'Help me check in, organize what feels heavy, and suggest one grounded next step.',
          label: label,
        ),
    };
  }

  AgentSkillBlueprint _buildSkillBlueprint({
    required SupportLabel primaryLabel,
    required SupportLabel secondaryLabel,
    required StressReport stressReport,
    required List<String> signalSources,
  }) {
    final tools = <AgentToolSuggestion>[
      const AgentToolSuggestion(
        toolId: 'chat_history_lookup',
        label: 'History lookup',
        reason:
            'Use recent prompts and selected labels to ground the next question.',
      ),
      if (signalSources.contains('Google Calendar'))
        const AgentToolSuggestion(
          toolId: 'calendar_signal_review',
          label: 'Calendar signals',
          reason:
              'Inspect imported schedule pressure before making planning suggestions.',
        ),
      if (signalSources.contains('Canvas'))
        const AgentToolSuggestion(
          toolId: 'canvas_course_scan',
          label: 'Canvas scan',
          reason:
              'Inspect assignment and course activity before making study suggestions.',
        ),
      const AgentToolSuggestion(
        toolId: 'stress_report_summarizer',
        label: 'Stress report',
        reason:
            'Use the current stress band to decide whether to ask, coach, or de-escalate.',
      ),
      _toolForLabel(primaryLabel),
      if (secondaryLabel != primaryLabel) _toolForLabel(secondaryLabel),
    ];

    final uniqueTools = <String, AgentToolSuggestion>{
      for (final tool in tools) tool.toolId: tool,
    }.values.toList(growable: false);

    final labelNames = {
      primaryLabel.displayName,
      secondaryLabel.displayName,
    }.join(' + ');
    final skillId =
        'support_${primaryLabel.storageKey}_${stressReport.band.name}_router';
    final title = '$labelNames Support Router';
    const summary =
        'Multi-agent support skill that uses labels, history, and workload signals to choose one clarifying question, one concrete suggestion, and one tool-backed next step.';
    final systemPrompt =
        'You are a multi-agent support coordinator for a student assistance workflow. Use the routing labels `${primaryLabel.storageKey}` and `${secondaryLabel.storageKey}`, the current `${stressReport.band.displayName}` stress band, and available history/import signals to: 1) ask one clarifying question, 2) give one concrete next-step suggestion, and 3) decide which tools to invoke before escalating to other agents. Prefer short, actionable guidance and explain why each chosen tool matters.';

    return AgentSkillBlueprint(
      skillId: skillId,
      title: title,
      summary: summary,
      systemPrompt: systemPrompt,
      starterPrompt:
          'Use the student label context, imported workload signals, and recent history to choose the next clarifying question and the next support action.',
      tools: uniqueTools,
    );
  }

  AgentToolSuggestion _toolForLabel(SupportLabel label) {
    return switch (label) {
      SupportLabel.planning => const AgentToolSuggestion(
          toolId: 'schedule_builder',
          label: 'Schedule builder',
          reason: 'Turn clustered deadlines and events into a two-day plan.',
        ),
      SupportLabel.writing => const AgentToolSuggestion(
          toolId: 'drafting_assistant',
          label: 'Drafting assistant',
          reason: 'Convert rough thoughts into a clear message or draft.',
        ),
      SupportLabel.studyHelp => const AgentToolSuggestion(
          toolId: 'concept_breakdown',
          label: 'Concept breakdown',
          reason: 'Break down a hard concept or assignment into study steps.',
        ),
      SupportLabel.summarization => const AgentToolSuggestion(
          toolId: 'summary_builder',
          label: 'Summary builder',
          reason: 'Condense long instructions or notes into key takeaways.',
        ),
      SupportLabel.imageAnalysis => const AgentToolSuggestion(
          toolId: 'visual_explainer',
          label: 'Visual explainer',
          reason:
              'Interpret screenshots, diagrams, or slides when text alone is not enough.',
        ),
      SupportLabel.wellbeingCheckIn => const AgentToolSuggestion(
          toolId: 'recovery_planner',
          label: 'Recovery planner',
          reason: 'De-escalate overload and choose one grounded next step.',
        ),
    };
  }
}
