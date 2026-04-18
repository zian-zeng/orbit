class ProfessorSignal {
  const ProfessorSignal({
    required this.name,
    this.averageRating,
    this.reviewCount = 0,
    this.averageGpa,
    this.sourceUrl,
    this.studentNotes = const [],
  });

  final String name;
  final double? averageRating;
  final int reviewCount;
  final double? averageGpa;
  final String? sourceUrl;
  final List<String> studentNotes;

  String get confidenceLabel {
    if (reviewCount >= 12) {
      return 'strong signal';
    }
    if (reviewCount >= 4) {
      return 'medium signal';
    }
    return 'low signal';
  }
}

class CourseCandidate {
  const CourseCandidate({
    required this.courseId,
    required this.title,
    required this.credits,
    required this.requirementTag,
    required this.workloadLevel,
    required this.projectLevel,
    this.averageGpa,
    this.description = '',
    this.sourceUrl,
    this.professors = const [],
    this.forumSignals = const [],
  });

  final String courseId;
  final String title;
  final int credits;
  final String requirementTag;
  final String workloadLevel;
  final String projectLevel;
  final double? averageGpa;
  final String description;
  final String? sourceUrl;
  final List<ProfessorSignal> professors;
  final List<String> forumSignals;

  bool get isHeavy =>
      workloadLevel == 'high' || projectLevel == 'high' || credits >= 4;
}

class CoursePlanRecommendation {
  const CoursePlanRecommendation({
    required this.course,
    required this.professor,
    required this.fitScore,
    required this.rationale,
    required this.riskFlags,
    required this.nextAction,
  });

  final CourseCandidate course;
  final ProfessorSignal? professor;
  final double fitScore;
  final List<String> rationale;
  final List<String> riskFlags;
  final String nextAction;

  String get scoreLabel => '${(fitScore * 100).round()}% fit';
}

class SemesterPlanReport {
  const SemesterPlanReport({
    required this.title,
    required this.targetCredits,
    required this.plannedCredits,
    required this.recommendations,
    required this.balanceSummary,
    required this.sourceNotes,
  });

  final String title;
  final int targetCredits;
  final int plannedCredits;
  final List<CoursePlanRecommendation> recommendations;
  final String balanceSummary;
  final List<String> sourceNotes;

  String get agentPromptSummary {
    final courseLines = recommendations.map((recommendation) {
      final professor = recommendation.professor?.name ?? 'TBD instructor';
      return '- ${recommendation.course.courseId} with $professor: '
          '${recommendation.scoreLabel}. ${recommendation.rationale.take(2).join(' ')}';
    });
    return [
      title,
      'Target credits: $targetCredits; planned credits: $plannedCredits',
      balanceSummary,
      ...courseLines,
      if (sourceNotes.isNotEmpty) 'Sources: ${sourceNotes.join(' | ')}',
    ].join('\n');
  }
}
