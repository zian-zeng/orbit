import 'package:chatbotapp/services/evaluation_readiness_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = EvaluationReadinessService();

  test('builds demo readiness report from fixture and local signals', () {
    final report = service.buildDemoReport(
      feedbackCount: 2,
      auditCount: 1,
      savedSkillCount: 1,
    );

    expect(report.fixtureSize, 40);
    expect(report.highStressCases, 25);
    expect(report.passedMetrics, report.totalMetrics);
    expect(report.readinessLabel, 'Strong demo readiness');
    expect(report.coursePlan.recommendations, isNotEmpty);
  });

  test('marks local learning signals missing before product use', () {
    final report = service.buildDemoReport();

    expect(
      report.metrics
          .where((metric) =>
              metric.label == 'Local feedback captured' && !metric.passed)
          .length,
      1,
    );
    expect(report.productionGaps,
        contains('Production auth and verified OAuth consent'));
  });
}
