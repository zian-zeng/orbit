import 'package:chatbotapp/models/course_planning.dart';

class UmdCoursePlanningService {
  const UmdCoursePlanningService();

  SemesterPlanReport buildDemoPlan({
    required Iterable<String> labels,
    double stressScore = 0.68,
    int targetCredits = 15,
  }) {
    return buildPlan(
      labels: labels,
      stressScore: stressScore,
      targetCredits: targetCredits,
      candidates: demoCandidates,
    );
  }

  SemesterPlanReport buildPlan({
    required Iterable<String> labels,
    required double stressScore,
    required int targetCredits,
    required List<CourseCandidate> candidates,
  }) {
    final normalizedLabels = labels
        .map((label) => label.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet();
    final sorted = candidates
        .map(
          (course) => _scoreCourse(
            course: course,
            labels: normalizedLabels,
            stressScore: stressScore,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => b.fitScore.compareTo(a.fitScore));

    final selected = <CoursePlanRecommendation>[];
    var credits = 0;
    var heavyCount = 0;
    for (final recommendation in sorted) {
      final course = recommendation.course;
      if (credits + course.credits > targetCredits + 1) {
        continue;
      }
      if (course.isHeavy && stressScore >= 0.55 && heavyCount >= 1) {
        continue;
      }
      selected.add(recommendation);
      credits += course.credits;
      if (course.isHeavy) {
        heavyCount++;
      }
      if (credits >= targetCredits - 1) {
        break;
      }
    }

    return SemesterPlanReport(
      title: 'UMD next-semester course plan',
      targetCredits: targetCredits,
      plannedCredits: credits,
      recommendations: selected,
      balanceSummary: _balanceSummary(
        selected: selected,
        stressScore: stressScore,
        labels: normalizedLabels,
      ),
      sourceNotes: const [
        'PlanetTerp: UMD professor reviews, course ratings, and historical grade data.',
        'umd.io/Testudo: official course and section structure should verify availability before registration.',
        'Forum/reddit sentiment should be summarized as anecdotal workload evidence, not a sole decision rule.',
      ],
    );
  }

  CoursePlanRecommendation _scoreCourse({
    required CourseCandidate course,
    required Set<String> labels,
    required double stressScore,
  }) {
    final professor = _bestProfessor(course.professors);
    var score = 0.52;
    final gpa = course.averageGpa;
    if (gpa != null) {
      score += ((gpa - 2.7) / 1.3).clamp(-0.12, 0.16);
    }
    final rating = professor?.averageRating;
    if (rating != null) {
      score += ((rating - 3.0) / 2.0).clamp(-0.12, 0.18);
    }
    if (professor != null && professor.reviewCount >= 8) {
      score += 0.04;
    }
    if (labels.contains('career_builder') &&
        course.requirementTag.contains('career')) {
      score += 0.1;
    }
    if (labels.contains('writing') &&
        course.requirementTag.contains('writing')) {
      score += 0.08;
    }
    if (labels.contains('commuter') && course.workloadLevel != 'high') {
      score += 0.04;
    }
    if (stressScore >= 0.55 && course.isHeavy) {
      score -= 0.18;
    }
    if (stressScore >= 0.55 && course.workloadLevel == 'moderate') {
      score += 0.06;
    }

    final riskFlags = <String>[
      if (course.isHeavy)
        'High workload/project signal. Avoid stacking with another heavy technical course.',
      if (professor != null && professor.reviewCount < 4)
        'Professor review confidence is low. Verify with more sources.',
      if (course.averageGpa != null && course.averageGpa! < 3.0)
        'Historical GPA suggests this may be a tougher course.',
    ];
    final rationale = <String>[
      '${course.courseId} fits ${course.requirementTag}.',
      if (professor != null)
        '${professor.name} has ${professor.confidenceLabel}${professor.averageRating == null ? '' : ' and ${professor.averageRating!.toStringAsFixed(1)}/5 average rating'}.',
      if (course.averageGpa != null)
        'Course average GPA signal: ${course.averageGpa!.toStringAsFixed(2)}.',
      if (labels.contains('stress_sensitive') || stressScore >= 0.55)
        'Plan is stress-aware: balance heavy courses with lower-friction requirements.',
      ...course.forumSignals.take(1),
    ];

    return CoursePlanRecommendation(
      course: course,
      professor: professor,
      fitScore: score.clamp(0.05, 0.98),
      rationale: rationale,
      riskFlags: riskFlags,
      nextAction:
          'Verify current sections in Testudo, then compare PlanetTerp reviews and recent syllabus/forum workload notes before registering.',
    );
  }

  ProfessorSignal? _bestProfessor(List<ProfessorSignal> professors) {
    if (professors.isEmpty) {
      return null;
    }
    final sorted = [...professors]..sort((a, b) {
        final aScore =
            (a.averageRating ?? 3.0) + (a.reviewCount >= 8 ? 0.2 : 0);
        final bScore =
            (b.averageRating ?? 3.0) + (b.reviewCount >= 8 ? 0.2 : 0);
        return bScore.compareTo(aScore);
      });
    return sorted.first;
  }

  String _balanceSummary({
    required List<CoursePlanRecommendation> selected,
    required double stressScore,
    required Set<String> labels,
  }) {
    final heavy = selected.where((item) => item.course.isHeavy).length;
    final technical = selected
        .where((item) =>
            RegExp(r'^(CMSC|MATH|STAT|ENEE)').hasMatch(item.course.courseId))
        .length;
    final preferenceText = labels.contains('commuter')
        ? ' It avoids assuming unlimited campus time for a commuter schedule.'
        : '';
    return 'Recommended mix: $heavy heavy course(s), $technical technical course(s), '
        'and ${selected.length - technical} balancing requirement(s). '
        'Stress score ${stressScore.toStringAsFixed(2)} means ORBIT should avoid a stacked high-workload semester.$preferenceText';
  }

  static const List<CourseCandidate> demoCandidates = [
    CourseCandidate(
      courseId: 'CMSC216',
      title: 'Introduction to Computer Systems',
      credits: 4,
      requirementTag: 'major requirement / systems foundation',
      workloadLevel: 'high',
      projectLevel: 'high',
      averageGpa: 2.86,
      sourceUrl: 'https://planetterp.com/course/CMSC216',
      professors: [
        ProfessorSignal(
          name: 'Larry Herman',
          averageRating: 4.1,
          reviewCount: 18,
          averageGpa: 2.95,
          sourceUrl: 'https://planetterp.com/professor/larry_herman',
          studentNotes: [
            'Often described as structured but project-heavy.',
          ],
        ),
      ],
      forumSignals: [
        'Anecdotal forum signal: projects can be time-consuming; start early.',
      ],
    ),
    CourseCandidate(
      courseId: 'STAT400',
      title: 'Applied Probability and Statistics I',
      credits: 3,
      requirementTag: 'technical requirement / quantitative',
      workloadLevel: 'medium',
      projectLevel: 'low',
      averageGpa: 3.08,
      sourceUrl: 'https://planetterp.com/course/STAT400',
      professors: [
        ProfessorSignal(
          name: 'Justin Wyss-Gallifent',
          averageRating: 4.6,
          reviewCount: 20,
          averageGpa: 3.22,
          sourceUrl: 'https://planetterp.com/professor/justin_wyss_gallifent',
        ),
      ],
      forumSignals: [
        'Anecdotal forum signal: exam practice matters more than projects.',
      ],
    ),
    CourseCandidate(
      courseId: 'ENGL101',
      title: 'Academic Writing',
      credits: 3,
      requirementTag: 'writing requirement / balancing course',
      workloadLevel: 'moderate',
      projectLevel: 'medium',
      averageGpa: 3.42,
      sourceUrl: 'https://planetterp.com/course/ENGL101',
      professors: [
        ProfessorSignal(
          name: 'TBD writing instructor',
          reviewCount: 0,
          averageGpa: 3.42,
        ),
      ],
      forumSignals: [
        'Structure varies by instructor; verify essay cadence in syllabus.',
      ],
    ),
    CourseCandidate(
      courseId: 'INST201',
      title: 'Introduction to Information Science',
      credits: 3,
      requirementTag: 'career exploration / data product pathway',
      workloadLevel: 'moderate',
      projectLevel: 'medium',
      averageGpa: 3.55,
      sourceUrl: 'https://planetterp.com/course/INST201',
      professors: [
        ProfessorSignal(
          name: 'Brian Butler',
          averageRating: 4.2,
          reviewCount: 12,
          averageGpa: 3.58,
          sourceUrl: 'https://planetterp.com/professor/brian_butler',
        ),
      ],
      forumSignals: [
        'Good fit for students exploring product, data, and human-centered systems.',
      ],
    ),
    CourseCandidate(
      courseId: 'MATH240',
      title: 'Introduction to Linear Algebra',
      credits: 4,
      requirementTag: 'technical requirement / math foundation',
      workloadLevel: 'high',
      projectLevel: 'low',
      averageGpa: 2.92,
      sourceUrl: 'https://planetterp.com/course/MATH240',
      professors: [
        ProfessorSignal(
          name: 'TBD math instructor',
          reviewCount: 0,
          averageGpa: 2.92,
        ),
      ],
      forumSignals: [
        'Anecdotal forum signal: proof comfort and weekly practice strongly affect stress.',
      ],
    ),
    CourseCandidate(
      courseId: 'COMM107',
      title: 'Oral Communication',
      credits: 3,
      requirementTag: 'gen-ed / communication balance',
      workloadLevel: 'moderate',
      projectLevel: 'medium',
      averageGpa: 3.63,
      sourceUrl: 'https://planetterp.com/course/COMM107',
      professors: [
        ProfessorSignal(
          name: 'TBD communication instructor',
          reviewCount: 0,
          averageGpa: 3.63,
        ),
      ],
      forumSignals: [
        'Usually presentation-based; check speech dates against exam weeks.',
      ],
    ),
  ];
}
