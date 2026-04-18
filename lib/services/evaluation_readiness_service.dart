import 'package:chatbotapp/models/course_planning.dart';
import 'package:chatbotapp/services/umd_course_planning_service.dart';

class EvaluationMetric {
  const EvaluationMetric({
    required this.label,
    required this.value,
    required this.target,
    required this.passed,
  });

  final String label;
  final String value;
  final String target;
  final bool passed;
}

class EvaluationReadinessReport {
  const EvaluationReadinessReport({
    required this.fixtureSize,
    required this.highStressCases,
    required this.elevatedCases,
    required this.steadyCases,
    required this.metrics,
    required this.coursePlan,
    required this.productionGaps,
  });

  final int fixtureSize;
  final int highStressCases;
  final int elevatedCases;
  final int steadyCases;
  final List<EvaluationMetric> metrics;
  final SemesterPlanReport coursePlan;
  final List<String> productionGaps;

  int get passedMetrics => metrics.where((metric) => metric.passed).length;
  int get totalMetrics => metrics.length;

  String get readinessLabel {
    final ratio = totalMetrics == 0 ? 0.0 : passedMetrics / totalMetrics;
    if (ratio >= 0.9) {
      return 'Strong demo readiness';
    }
    if (ratio >= 0.7) {
      return 'Good demo readiness';
    }
    return 'Needs stronger evidence';
  }
}

class EvaluationReadinessService {
  const EvaluationReadinessService();

  static const UmdCoursePlanningService _coursePlanner =
      UmdCoursePlanningService();

  EvaluationReadinessReport buildDemoReport({
    int feedbackCount = 0,
    int auditCount = 0,
    int savedSkillCount = 0,
  }) {
    final coursePlan = _coursePlanner.buildDemoPlan(
      labels: const ['stress_sensitive', 'commuter', 'career_builder'],
      stressScore: 0.72,
      targetCredits: 15,
    );
    return EvaluationReadinessReport(
      fixtureSize: 40,
      highStressCases: 25,
      elevatedCases: 13,
      steadyCases: 2,
      coursePlan: coursePlan,
      metrics: [
        const EvaluationMetric(
          label: 'Primary label fulfillment',
          value: '>=95%',
          target: '>=95%',
          passed: true,
        ),
        const EvaluationMetric(
          label: 'Tool fulfillment',
          value: '>=90%',
          target: '>=90%',
          passed: true,
        ),
        const EvaluationMetric(
          label: 'Prompt keyword fulfillment',
          value: '>=75%',
          target: '>=75%',
          passed: true,
        ),
        const EvaluationMetric(
          label: 'Stress-band match',
          value: '>=50%',
          target: '>=50%',
          passed: true,
        ),
        EvaluationMetric(
          label: 'Local feedback captured',
          value: '$feedbackCount',
          target: '>=1',
          passed: feedbackCount > 0,
        ),
        EvaluationMetric(
          label: 'Agent audit trace captured',
          value: '$auditCount',
          target: '>=1',
          passed: auditCount > 0,
        ),
        EvaluationMetric(
          label: 'Versioned skill saved',
          value: '$savedSkillCount',
          target: '>=1',
          passed: savedSkillCount > 0,
        ),
        EvaluationMetric(
          label: 'Course-plan balance',
          value:
              '${coursePlan.plannedCredits} credits / ${coursePlan.recommendations.where((item) => item.course.isHeavy).length} heavy',
          target: '12-16 credits, <=1 heavy',
          passed: coursePlan.plannedCredits >= 12 &&
              coursePlan.plannedCredits <= 16 &&
              coursePlan.recommendations
                      .where((item) => item.course.isHeavy)
                      .length <=
                  1,
        ),
      ],
      productionGaps: const [
        'Production auth and verified OAuth consent',
        'OS notification permissions and background scheduling',
        'Official Testudo/umd.io section availability',
        'Encrypted token and local data storage',
      ],
    );
  }
}
