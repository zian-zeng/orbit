enum SupportLabel {
  planning,
  writing,
  studyHelp,
  summarization,
  imageAnalysis,
  wellbeingCheckIn,
}

String? supportLabelKey(SupportLabel? label) => label?.storageKey;

SupportLabel? supportLabelFromKey(String? key) {
  if (key == null || key.trim().isEmpty) {
    return null;
  }

  for (final label in SupportLabel.values) {
    if (label.storageKey == key) {
      return label;
    }
  }

  return null;
}

List<SupportLabel> supportLabelsFromKeys(Iterable<String> keys) {
  final labels = <SupportLabel>[];
  for (final key in keys) {
    final label = supportLabelFromKey(key);
    if (label != null) {
      labels.add(label);
    }
  }
  return labels;
}

extension SupportLabelPresentation on SupportLabel {
  String get storageKey => switch (this) {
    SupportLabel.planning => 'planning',
    SupportLabel.writing => 'writing',
    SupportLabel.studyHelp => 'study_help',
    SupportLabel.summarization => 'summarization',
    SupportLabel.imageAnalysis => 'image_analysis',
    SupportLabel.wellbeingCheckIn => 'wellbeing_checkin',
  };

  String get displayName => switch (this) {
    SupportLabel.planning => 'Planning',
    SupportLabel.writing => 'Writing',
    SupportLabel.studyHelp => 'Study help',
    SupportLabel.summarization => 'Summarize',
    SupportLabel.imageAnalysis => 'Image analysis',
    SupportLabel.wellbeingCheckIn => 'Check-in',
  };
}

class RoutingContext {
  const RoutingContext({
    required this.draftText,
    required this.selectedLabel,
    required this.hasImages,
    required this.recentLabels,
    required this.preferredLabels,
  });

  final String draftText;
  final SupportLabel? selectedLabel;
  final bool hasImages;
  final List<SupportLabel> recentLabels;
  final List<SupportLabel> preferredLabels;

  String get trimmedDraftText => draftText.trim();
}

class PromptRecommendation {
  const PromptRecommendation({
    required this.label,
    required this.templateId,
    required this.skillId,
    required this.title,
    required this.description,
    required this.promptTemplate,
    required this.reason,
    required this.score,
  });

  final SupportLabel label;
  final String templateId;
  final String skillId;
  final String title;
  final String description;
  final String promptTemplate;
  final String reason;
  final int score;
}
