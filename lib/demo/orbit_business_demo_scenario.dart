import 'package:chatbotapp/data_sources/student_data_models.dart';

class DemoWorkloadDay {
  const DemoWorkloadDay({
    required this.label,
    required this.deadlines,
    required this.calendarHours,
    required this.stressScore,
  });

  final String label;
  final int deadlines;
  final double calendarHours;
  final double stressScore;
}

class DemoAlert {
  const DemoAlert({
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String title;
  final String detail;
  final DemoAlertSeverity severity;
}

enum DemoAlertSeverity {
  info,
  warning,
  urgent,
}

class OrbitBusinessDemoScenario {
  OrbitBusinessDemoScenario._({
    required this.studentName,
    required this.email,
    required this.persona,
    required this.preferenceLabels,
    required this.demoPrompt,
    required this.snapshot,
    required this.week,
    required this.alerts,
    required this.agentTools,
    required this.datasetSummary,
  });

  final String studentName;
  final String email;
  final String persona;
  final List<String> preferenceLabels;
  final String demoPrompt;
  final StudentSignalSnapshot snapshot;
  final List<DemoWorkloadDay> week;
  final List<DemoAlert> alerts;
  final List<String> agentTools;
  final String datasetSummary;

  String get firstName => studentName.split(' ').first;

  factory OrbitBusinessDemoScenario.veganUmdStudent() {
    final now = DateTime.now();
    final snapshot = StudentSignalSnapshot(
      fetchedAt: now,
      assignments: [
        StudentAssignment(
          id: 'canvas-cmsc216-project-3',
          courseId: 'cmsc216',
          courseName: 'CMSC216',
          name: 'Project 3 checkpoint',
          dueAt: now.add(const Duration(days: 1, hours: 6)),
          pointsPossible: 100,
          htmlUrl: 'https://umd.instructure.com/courses/cmsc216',
        ),
        StudentAssignment(
          id: 'canvas-stat400-quiz',
          courseId: 'stat400',
          courseName: 'STAT400',
          name: 'Probability quiz',
          dueAt: now.add(const Duration(days: 2, hours: 4)),
          pointsPossible: 25,
          htmlUrl: 'https://umd.instructure.com/courses/stat400',
        ),
        StudentAssignment(
          id: 'canvas-engl101-draft',
          courseId: 'engl101',
          courseName: 'ENGL101',
          name: 'Research memo draft',
          dueAt: now.add(const Duration(days: 4)),
          pointsPossible: 40,
          htmlUrl: 'https://umd.instructure.com/courses/engl101',
        ),
        StudentAssignment(
          id: 'canvas-cmsc216-lab',
          courseId: 'cmsc216',
          courseName: 'CMSC216',
          name: 'Systems lab reflection',
          dueAt: now.add(const Duration(days: 5)),
          pointsPossible: 15,
        ),
        StudentAssignment(
          id: 'canvas-stat400-homework',
          courseId: 'stat400',
          courseName: 'STAT400',
          name: 'Homework 8',
          dueAt: now.add(const Duration(days: 6)),
          pointsPossible: 30,
        ),
        StudentAssignment(
          id: 'canvas-inst201-reading',
          courseId: 'inst201',
          courseName: 'INST201',
          name: 'Reading response',
          dueAt: now.add(const Duration(days: 6, hours: 8)),
          pointsPossible: 10,
        ),
      ],
      calendarEvents: [
        StudentCalendarEvent(
          id: 'calendar-cmsc216-lecture',
          title: 'CMSC216 lecture',
          start: now.add(const Duration(hours: 3)),
          end: now.add(const Duration(hours: 4, minutes: 15)),
          location: 'IRB 0324',
        ),
        StudentCalendarEvent(
          id: 'calendar-stat400-discussion',
          title: 'STAT400 discussion',
          start: now.add(const Duration(hours: 5)),
          end: now.add(const Duration(hours: 6)),
          location: 'ESJ 0202',
        ),
        StudentCalendarEvent(
          id: 'calendar-part-time-shift',
          title: 'Part-time work shift',
          start: now.add(const Duration(hours: 8)),
          end: now.add(const Duration(hours: 13)),
          location: 'College Park',
        ),
        StudentCalendarEvent(
          id: 'calendar-study-group',
          title: 'Project study group',
          start: now.add(const Duration(days: 1, hours: 1)),
          end: now.add(const Duration(days: 1, hours: 3)),
          location: 'McKeldin Library',
        ),
        StudentCalendarEvent(
          id: 'calendar-career-fair-prep',
          title: 'Career fair prep',
          start: now.add(const Duration(days: 2, hours: 2)),
          end: now.add(const Duration(days: 2, hours: 3, minutes: 30)),
          location: 'University Career Center',
        ),
        StudentCalendarEvent(
          id: 'calendar-cmsc216-deep-work',
          title: 'CMSC216 project block',
          start: now.add(const Duration(days: 3, hours: 2)),
          end: now.add(const Duration(days: 3, hours: 6)),
          location: 'McKeldin Library',
        ),
        StudentCalendarEvent(
          id: 'calendar-weekend-shift',
          title: 'Weekend work shift',
          start: now.add(const Duration(days: 5, hours: 4)),
          end: now.add(const Duration(days: 5, hours: 10)),
          location: 'College Park',
        ),
        StudentCalendarEvent(
          id: 'calendar-stat400-review',
          title: 'STAT400 review session',
          start: now.add(const Duration(days: 6, hours: 1)),
          end: now.add(const Duration(days: 6, hours: 4)),
          location: 'ESJ',
        ),
      ],
      routes: const [
        CampusRoute(
          origin: 'IRB, College Park, MD',
          destination: 'Vegan food near University of Maryland College Park',
          travelMode: 'WALK',
          duration: Duration(minutes: 12),
          distanceMeters: 920,
        ),
      ],
      places: const [
        CampusPlace(
          name: 'Maryland Hillel Cafe',
          formattedAddress: '7612 Mowatt Ln, College Park, MD',
          googleMapsUri: 'https://maps.google.com/?q=Maryland+Hillel+Cafe',
          servesVegetarianFood: true,
          reason:
              'Matched live Google Places query: vegan food near University of Maryland College Park',
        ),
        CampusPlace(
          name: 'NuVegan Cafe',
          formattedAddress: 'College Park area',
          googleMapsUri: 'https://maps.google.com/?q=NuVegan+Cafe',
          servesVegetarianFood: true,
          reason:
              'Matched vegan preference from profile and recent chat history.',
        ),
      ],
      sourceNotes: const [
        'Demo fixture: Canvas deadlines, Google Calendar pressure, Google Places vegan search, and campus walking route are preloaded for a reliable desktop/web pitch.',
      ],
    );

    return OrbitBusinessDemoScenario._(
      studentName: 'Maya Chen',
      email: 'maya.chen@umd.edu',
      persona:
          'UMD sophomore, vegan, commuting between IRB, McKeldin, and a part-time shift.',
      preferenceLabels: const [
        'vegan',
        'plant_based',
        'academic_planning',
        'stress_sensitive',
        'life_logistics',
        'campus_navigation',
      ],
      demoPrompt:
          'I am vegan and I have class near IRB, a work shift later, and multiple Canvas deadlines. Find food near campus and tell me what I should do next without making my stress worse.',
      snapshot: snapshot,
      week: const [
        DemoWorkloadDay(
          label: 'Mon',
          deadlines: 1,
          calendarHours: 5.5,
          stressScore: 0.62,
        ),
        DemoWorkloadDay(
          label: 'Tue',
          deadlines: 2,
          calendarHours: 8.0,
          stressScore: 0.86,
        ),
        DemoWorkloadDay(
          label: 'Wed',
          deadlines: 1,
          calendarHours: 6.5,
          stressScore: 0.74,
        ),
        DemoWorkloadDay(
          label: 'Thu',
          deadlines: 0,
          calendarHours: 4.0,
          stressScore: 0.45,
        ),
        DemoWorkloadDay(
          label: 'Fri',
          deadlines: 1,
          calendarHours: 5.0,
          stressScore: 0.58,
        ),
        DemoWorkloadDay(
          label: 'Sat',
          deadlines: 0,
          calendarHours: 2.0,
          stressScore: 0.31,
        ),
        DemoWorkloadDay(
          label: 'Sun',
          deadlines: 1,
          calendarHours: 3.0,
          stressScore: 0.52,
        ),
      ],
      alerts: const [
        DemoAlert(
          title: 'High stress window',
          detail:
              'Two Canvas deadlines and 8 scheduled hours land in the next 48 hours. Keep the next action under 20 minutes.',
          severity: DemoAlertSeverity.urgent,
        ),
        DemoAlert(
          title: 'Movement break',
          detail:
              'Laptop focus block has reached the 45-minute break threshold. Take a 10-minute walk before the next study block.',
          severity: DemoAlertSeverity.warning,
        ),
        DemoAlert(
          title: 'Food constraint applied',
          detail:
              'The food search uses vegan and plant-based labels automatically.',
          severity: DemoAlertSeverity.info,
        ),
      ],
      agentTools: const [
        'chat_history_lookup',
        'stress_report_summarizer',
        'canvas_course_scan',
        'calendar_signal_review',
        'live_places_search',
        'campus_route_planner',
      ],
      datasetSummary:
          'Calibrated against the reproducible 40-user support-intelligence fixture: 25 high-stress, 13 elevated, and 2 steady synthetic UMD profiles.',
    );
  }
}
