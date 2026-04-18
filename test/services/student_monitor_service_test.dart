import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = StudentMonitorService();

  test('falls back to the polished demo when no live signals exist', () {
    final report = service.build(
      studentName: 'Taylor',
      email: 'taylor@umd.edu',
      profileLabels: const ['vegan'],
      snapshot: StudentSignalSnapshot.empty(),
      fallback: OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    expect(report.isLive, isFalse);
    expect(report.studentName, 'Maya Chen');
    expect(report.snapshot.places.first.reason, contains('vegan food'));
  });

  test('builds live monitor report from connected Canvas and Calendar signals',
      () {
    final now = DateTime.now();
    final report = service.build(
      studentName: 'Taylor Kim',
      email: 'taylor@umd.edu',
      profileLabels: const ['vegan', 'movement_breaks', 'campus_navigation'],
      snapshot: StudentSignalSnapshot(
        fetchedAt: now,
        assignments: [
          StudentAssignment(
            id: 'a1',
            courseId: 'cmsc216',
            name: 'Project',
            dueAt: now.add(const Duration(days: 1)),
          ),
        ],
        calendarEvents: [
          StudentCalendarEvent(
            id: 'e1',
            title: 'Work shift',
            start: now.add(const Duration(hours: 2)),
            end: now.add(const Duration(hours: 8)),
          ),
        ],
        routes: const [],
        places: const [],
        sourceNotes: const ['Google Places not configured.'],
      ),
      fallback: OrbitBusinessDemoScenario.veganUmdStudent(),
    );

    expect(report.isLive, isTrue);
    expect(report.studentName, 'Taylor Kim');
    expect(report.agentTools, contains('canvas_course_scan'));
    expect(report.agentTools, contains('calendar_signal_review'));
    expect(report.agentTools, contains('live_places_search'));
    expect(report.alerts.map((alert) => alert.title),
        contains('Movement break ready'));
  });
}
