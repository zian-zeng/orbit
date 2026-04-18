import 'dart:convert';
import 'dart:io';

import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo scenario is calibrated to the 40-user evaluation fixture', () {
    final raw = jsonDecode(
      File('test/fixtures/support_intelligence_eval_dataset.json')
          .readAsStringSync(),
    ) as List<dynamic>;
    final stressCounts = <String, int>{};
    for (final item in raw.whereType<Map<String, dynamic>>()) {
      final band = item['expected_stress_band'] as String;
      stressCounts[band] = (stressCounts[band] ?? 0) + 1;
    }

    final scenario = OrbitBusinessDemoScenario.veganUmdStudent();

    expect(raw, hasLength(40));
    expect(stressCounts['high'], 25);
    expect(stressCounts['elevated'], 13);
    expect(stressCounts['steady'], 2);
    expect(scenario.datasetSummary, contains('40-user'));
    expect(scenario.datasetSummary, contains('25 high-stress'));
  });

  test('demo scenario produces a high stress student snapshot', () {
    final scenario = OrbitBusinessDemoScenario.veganUmdStudent();

    expect(scenario.preferenceLabels, contains('vegan'));
    expect(scenario.snapshot.assignments, hasLength(6));
    expect(scenario.snapshot.places.first.reason, contains('vegan food'));
    expect(scenario.snapshot.stressRiskScore, greaterThanOrEqualTo(0.9));
  });
}
