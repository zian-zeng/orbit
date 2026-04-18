import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:chatbotapp/services/student_notification_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const monitorService = StudentMonitorService();
  const policy = StudentNotificationPolicy();

  test('raises stress notification from the demo report', () {
    final now = DateTime.now();
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final plan = policy.build(report: report, now: now);

    expect(plan.notifications.map((alert) => alert.title),
        contains('Stress limit reached'));
  });

  test('raises deadline notification when assignment is inside 24 hours', () {
    final now = DateTime(2026, 4, 18, 14);
    final report = monitorService.build(
      studentName: 'Taylor',
      email: 'taylor@umd.edu',
      profileLabels: const [],
      snapshot: StudentSignalSnapshot(
        fetchedAt: now,
        assignments: [
          StudentAssignment(
            id: 'assignment-1',
            courseId: 'cmsc216',
            name: 'Project checkpoint',
            dueAt: now.add(const Duration(hours: 2)),
          ),
        ],
        calendarEvents: const [],
        routes: const [],
        places: const [],
        sourceNotes: const [],
      ),
      fallback: OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final plan = policy.build(report: report, now: now);

    expect(plan.notifications.map((alert) => alert.title),
        contains('Deadline inside 24 hours'));
  });

  test('raises laptop break notification after the custom focus threshold', () {
    final now = DateTime(2026, 4, 18, 14);
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final plan = policy.build(
      report: report,
      now: now,
      focusStartedAt: now.subtract(const Duration(minutes: 50)),
      focusBreakMinutes: 45,
    );

    expect(plan.needsBreak, isTrue);
    expect(plan.focusDurationLabel, '50 min');
    expect(plan.notifications.map((alert) => alert.title),
        contains('Laptop break due'));
  });

  test('quiet hours suppress non-urgent nudges but keep urgent alerts', () {
    final now = DateTime(2026, 4, 18, 23);
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final plan = policy.build(
      report: report,
      now: now,
      focusStartedAt: now.subtract(const Duration(minutes: 50)),
      focusBreakMinutes: 45,
      quietHoursEnabled: true,
      quietHoursStart: 22,
      quietHoursEnd: 8,
    );

    expect(plan.quietHoursActive, isTrue);
    expect(plan.suppressedCount, greaterThan(0));
    expect(plan.notifications.map((alert) => alert.title),
        contains('Stress limit reached'));
    expect(plan.notifications.map((alert) => alert.title),
        isNot(contains('Laptop break due')));
  });

  test('high sensitivity raises earlier deadline nudges', () {
    final now = DateTime(2026, 4, 18, 14);
    final report = monitorService.build(
      studentName: 'Taylor',
      email: 'taylor@umd.edu',
      profileLabels: const [],
      snapshot: StudentSignalSnapshot(
        fetchedAt: now,
        assignments: [
          StudentAssignment(
            id: 'assignment-1',
            courseId: 'cmsc216',
            name: 'Project checkpoint',
            dueAt: now.add(const Duration(hours: 30)),
          ),
        ],
        calendarEvents: const [],
        routes: const [],
        places: const [],
        sourceNotes: const [],
      ),
      fallback: OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    final balanced = policy.build(report: report, now: now, sensitivity: 1);
    final high = policy.build(report: report, now: now, sensitivity: 2);

    expect(balanced.notifications.map((alert) => alert.title),
        isNot(contains('Deadline inside 24 hours')));
    expect(high.notifications.map((alert) => alert.title),
        contains('Deadline inside 24 hours'));
  });

  test('disabled notifications return a paused plan', () {
    final report = monitorService.fromDemo(
      OrbitBusinessDemoScenario.veganUmdStudent(),
    );
    final plan = policy.build(
      report: report,
      notificationsEnabled: false,
    );

    expect(plan.notificationsEnabled, isFalse);
    expect(plan.notifications.single.title, 'Notifications paused');
  });
}
