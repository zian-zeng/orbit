import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';

class StudentMonitorReport {
  const StudentMonitorReport({
    required this.studentName,
    required this.email,
    required this.subtitle,
    required this.profileLabels,
    required this.prompt,
    required this.snapshot,
    required this.week,
    required this.alerts,
    required this.agentTools,
    required this.datasetSummary,
    required this.isLive,
  });

  final String studentName;
  final String email;
  final String subtitle;
  final List<String> profileLabels;
  final String prompt;
  final StudentSignalSnapshot snapshot;
  final List<DemoWorkloadDay> week;
  final List<DemoAlert> alerts;
  final List<String> agentTools;
  final String datasetSummary;
  final bool isLive;

  String get firstName => studentName.split(' ').first;
  bool get hasSignals =>
      snapshot.assignments.isNotEmpty ||
      snapshot.calendarEvents.isNotEmpty ||
      snapshot.routes.isNotEmpty ||
      snapshot.places.isNotEmpty;
}

class StudentMonitorService {
  const StudentMonitorService();

  StudentMonitorReport build({
    required String studentName,
    required String email,
    required Iterable<String> profileLabels,
    required StudentSignalSnapshot? snapshot,
    required OrbitBusinessDemoScenario fallback,
  }) {
    final labels = _normalizeLabels(profileLabels);
    final liveSnapshot = snapshot;
    if (liveSnapshot == null || !_hasSignals(liveSnapshot)) {
      return fromDemo(fallback);
    }

    return StudentMonitorReport(
      studentName:
          studentName.trim().isEmpty ? fallback.studentName : studentName,
      email: email.trim().isEmpty ? fallback.email : email,
      subtitle: 'Live student monitor from connected signals',
      profileLabels: labels.isEmpty ? fallback.preferenceLabels : labels,
      prompt: _promptForLiveSnapshot(liveSnapshot, labels),
      snapshot: liveSnapshot,
      week: _buildWeek(liveSnapshot),
      alerts: _buildAlerts(liveSnapshot, labels),
      agentTools: _buildTools(liveSnapshot, labels),
      datasetSummary:
          '${fallback.datasetSummary} Live mode is currently using connected Canvas, Google Calendar, Routes, and Places signals when configured.',
      isLive: true,
    );
  }

  StudentMonitorReport fromDemo(OrbitBusinessDemoScenario scenario) {
    return StudentMonitorReport(
      studentName: scenario.studentName,
      email: scenario.email,
      subtitle: scenario.persona,
      profileLabels: scenario.preferenceLabels,
      prompt: scenario.demoPrompt,
      snapshot: scenario.snapshot,
      week: scenario.week,
      alerts: scenario.alerts,
      agentTools: scenario.agentTools,
      datasetSummary: scenario.datasetSummary,
      isLive: false,
    );
  }

  List<DemoWorkloadDay> _buildWeek(StudentSignalSnapshot snapshot) {
    final now = DateTime.now();
    return List<DemoWorkloadDay>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day).add(
        Duration(days: index),
      );
      final nextDay = day.add(const Duration(days: 1));
      final deadlines = snapshot.assignments.where((assignment) {
        final dueAt = assignment.dueAt;
        return dueAt != null && !dueAt.isBefore(day) && dueAt.isBefore(nextDay);
      }).length;
      final calendarMinutes = snapshot.calendarEvents.where((event) {
        final start = event.start;
        return start != null && !start.isBefore(day) && start.isBefore(nextDay);
      }).fold<int>(
        0,
        (total, event) => total + event.duration.inMinutes,
      );
      final calendarHours = calendarMinutes / 60.0;
      final deadlinePressure = (deadlines / 3).clamp(0.0, 1.0);
      final calendarPressure = (calendarHours / 8).clamp(0.0, 1.0);
      final stressScore =
          ((deadlinePressure * 0.58) + (calendarPressure * 0.42))
              .clamp(0.0, 1.0);
      return DemoWorkloadDay(
        label: _weekdayLabel(day.weekday),
        deadlines: deadlines,
        calendarHours: calendarHours,
        stressScore: stressScore,
      );
    });
  }

  List<DemoAlert> _buildAlerts(
    StudentSignalSnapshot snapshot,
    List<String> labels,
  ) {
    final alerts = <DemoAlert>[];
    if (snapshot.stressRiskScore >= 0.72) {
      alerts.add(
        const DemoAlert(
          title: 'High stress window',
          detail:
              'Canvas deadlines and calendar load are both high. Keep the next action under 20 minutes.',
          severity: DemoAlertSeverity.urgent,
        ),
      );
    } else if (snapshot.stressRiskScore >= 0.48) {
      alerts.add(
        const DemoAlert(
          title: 'Elevated pressure',
          detail:
              'The next week has enough load to justify a short triage plan.',
          severity: DemoAlertSeverity.warning,
        ),
      );
    } else {
      alerts.add(
        const DemoAlert(
          title: 'Steady workload',
          detail: 'No severe workload spike detected from connected signals.',
          severity: DemoAlertSeverity.info,
        ),
      );
    }

    if (labels.contains('movement_breaks') ||
        labels.contains('notification_breaks')) {
      alerts.add(
        const DemoAlert(
          title: 'Movement break ready',
          detail:
              'When focus passes the student break threshold, Orbit should nudge a 10-minute walk or reset.',
          severity: DemoAlertSeverity.warning,
        ),
      );
    }
    if (_hasFoodPreference(labels) || snapshot.places.isNotEmpty) {
      alerts.add(
        const DemoAlert(
          title: 'Food constraint applied',
          detail:
              'Dining and location suggestions use the stored food preference labels before search.',
          severity: DemoAlertSeverity.info,
        ),
      );
    }
    if (snapshot.sourceNotes.isNotEmpty) {
      alerts.add(
        DemoAlert(
          title: 'Connector status',
          detail: snapshot.sourceNotes.take(2).join(' '),
          severity: DemoAlertSeverity.info,
        ),
      );
    }
    return alerts;
  }

  List<String> _buildTools(
      StudentSignalSnapshot snapshot, List<String> labels) {
    return [
      'chat_history_lookup',
      'stress_report_summarizer',
      if (snapshot.assignments.isNotEmpty) 'canvas_course_scan',
      if (snapshot.calendarEvents.isNotEmpty) 'calendar_signal_review',
      if (snapshot.places.isNotEmpty || _hasFoodPreference(labels))
        'live_places_search',
      if (snapshot.routes.isNotEmpty || labels.contains('campus_navigation'))
        'campus_route_planner',
      if (labels.contains('career_builder')) 'career_timeline_builder',
    ];
  }

  String _promptForLiveSnapshot(
    StudentSignalSnapshot snapshot,
    List<String> labels,
  ) {
    final foodText = _hasFoodPreference(labels)
        ? ' Use my food preferences automatically.'
        : '';
    return 'Use my connected UMD signals to plan the next 24 hours. I have '
        '${snapshot.deadlinesNextSevenDays} Canvas deadlines and '
        '${snapshot.calendarHoursNextSevenDays.toStringAsFixed(1)} scheduled hours this week.$foodText';
  }

  List<String> _normalizeLabels(Iterable<String> labels) {
    return labels
        .map((label) => label.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort();
  }

  bool _hasSignals(StudentSignalSnapshot snapshot) {
    return snapshot.assignments.isNotEmpty ||
        snapshot.calendarEvents.isNotEmpty ||
        snapshot.routes.isNotEmpty ||
        snapshot.places.isNotEmpty;
  }

  bool _hasFoodPreference(List<String> labels) {
    return labels.any(
      const {
        'vegan',
        'plant_based',
        'vegetarian',
        'halal',
        'kosher',
        'gluten_free',
        'food_allergy',
        'dietary_restriction',
      }.contains,
    );
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => 'Day',
    };
  }
}
