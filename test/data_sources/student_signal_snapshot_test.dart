import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computes UMD student workload labels from assignments and calendar',
      () {
    final now = DateTime.now();
    final snapshot = StudentSignalSnapshot(
      fetchedAt: now,
      assignments: List.generate(
        5,
        (index) => StudentAssignment(
          id: '$index',
          courseId: 'cmsc${index + 1}',
          name: 'Assignment $index',
          dueAt: now.add(Duration(days: index + 1)),
        ),
      ),
      calendarEvents: [
        StudentCalendarEvent(
          id: 'event-1',
          title: 'Study block',
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 1, hours: 2)),
        ),
      ],
      routes: const [
        CampusRoute(
          origin: 'McKeldin Library',
          destination: 'University Health Center',
          travelMode: 'walk',
          duration: Duration(minutes: 12),
          distanceMeters: 900,
        ),
      ],
      places: const [],
      sourceNotes: const [],
    );

    expect(snapshot.deadlinesNextSevenDays, 5);
    expect(snapshot.calendarHoursNextSevenDays, closeTo(2, 0.01));
    expect(snapshot.stressRiskScore, greaterThan(0.4));
    expect(snapshot.inferredLabelKeys, contains('academic_planning'));
    expect(snapshot.inferredLabelKeys, contains('campus_navigation'));
  });
}
