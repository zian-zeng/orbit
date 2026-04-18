import 'package:chatbotapp/data_sources/umd_resource_catalog.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/services/student_action_plan_service.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const monitorService = StudentMonitorService();
  const actionPlanService = StudentActionPlanService();
  const resourceCatalog = UmdResourceCatalog();

  test('turns demo signals into a concrete next-best-action plan', () {
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final resources = resourceCatalog.match(
      message: report.prompt,
      labels: report.profileLabels,
    );

    final plan = actionPlanService.build(
      report: report,
      resources: resources,
      focusBreakMinutes: 45,
    );

    expect(plan.headline, contains('Maya'));
    expect(
        plan.steps.map((step) => step.toolId), contains('canvas_course_scan'));
    expect(
      plan.steps.map((step) => step.toolId),
      contains('live_places_search'),
    );
    expect(
      plan.steps.map((step) => step.title),
      contains('Use a 45-minute focus boundary'),
    );
    expect(plan.agentHandoff, contains('academic_planning_agent'));
    expect(plan.agentHandoff, contains('life_logistics_agent'));
    expect(plan.skillPrompt, contains('dietary'));
  });
}
