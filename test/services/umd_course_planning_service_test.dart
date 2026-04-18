import 'package:chatbotapp/services/umd_course_planning_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = UmdCoursePlanningService();

  test('builds a stress-aware UMD next semester plan', () {
    final plan = service.buildDemoPlan(
      labels: const ['stress_sensitive', 'commuter', 'career_builder'],
      stressScore: 0.72,
    );

    expect(plan.recommendations, isNotEmpty);
    expect(plan.plannedCredits, inInclusiveRange(12, 16));
    expect(
      plan.recommendations.where((item) => item.course.isHeavy),
      hasLength(lessThanOrEqualTo(1)),
    );
    expect(plan.balanceSummary, contains('avoid a stacked high-workload'));
    expect(plan.agentPromptSummary, contains('PlanetTerp'));
  });

  test('uses professor rating and requirement fit in ranking', () {
    final plan = service.buildDemoPlan(
      labels: const ['career_builder'],
      stressScore: 0.28,
    );

    expect(plan.recommendations.first.course.courseId, 'INST201');
    expect(plan.recommendations.first.professor?.name, 'Brian Butler');
    expect(plan.recommendations.first.rationale.join(' '),
        contains('career exploration'));
  });
}
