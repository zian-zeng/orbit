import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';

class StudentNotificationPlan {
  const StudentNotificationPlan({
    required this.generatedAt,
    required this.focusDuration,
    required this.notifications,
  });

  final DateTime generatedAt;
  final Duration focusDuration;
  final List<DemoAlert> notifications;

  bool get hasActiveFocusSession => focusDuration > Duration.zero;
  bool get needsBreak => notifications.any(
        (notification) => notification.title == 'Laptop break due',
      );

  String get focusDurationLabel {
    if (!hasActiveFocusSession) {
      return 'Not tracking';
    }
    final hours = focusDuration.inHours;
    final minutes = focusDuration.inMinutes.remainder(60);
    if (hours <= 0) {
      return '$minutes min';
    }
    return '${hours}h ${minutes}m';
  }
}

class StudentNotificationPolicy {
  const StudentNotificationPolicy();

  StudentNotificationPlan build({
    required StudentMonitorReport report,
    DateTime? focusStartedAt,
    DateTime? now,
    int focusBreakMinutes = 45,
  }) {
    final generatedAt = now ?? DateTime.now();
    final breakThreshold = Duration(
      minutes: focusBreakMinutes.clamp(15, 180),
    );
    final focusDuration = _focusDuration(
      focusStartedAt: focusStartedAt,
      now: generatedAt,
    );
    final notifications = <DemoAlert>[
      ..._stressNotifications(report),
      ..._deadlineNotifications(report.snapshot, generatedAt),
      ..._focusNotifications(focusDuration, breakThreshold),
    ];

    if (notifications.isEmpty) {
      notifications.add(
        const DemoAlert(
          title: 'No urgent nudges',
          detail:
              'Orbit is watching workload, deadlines, and focus duration. No immediate intervention is needed.',
          severity: DemoAlertSeverity.info,
        ),
      );
    }

    return StudentNotificationPlan(
      generatedAt: generatedAt,
      focusDuration: focusDuration,
      notifications: notifications,
    );
  }

  List<DemoAlert> _stressNotifications(StudentMonitorReport report) {
    final score = report.snapshot.stressRiskScore;
    if (score >= 0.72) {
      return const [
        DemoAlert(
          title: 'Stress limit reached',
          detail:
              'The workload risk is high. Ask ORBIT for a 20-minute triage plan before adding new tasks.',
          severity: DemoAlertSeverity.urgent,
        ),
      ];
    }
    if (score >= 0.48) {
      return const [
        DemoAlert(
          title: 'Stress is rising',
          detail:
              'Pressure is elevated. A short schedule cleanup can prevent a late-night pileup.',
          severity: DemoAlertSeverity.warning,
        ),
      ];
    }
    return const [];
  }

  List<DemoAlert> _deadlineNotifications(
    StudentSignalSnapshot snapshot,
    DateTime now,
  ) {
    final upcoming = snapshot.assignments.where((assignment) {
      final dueAt = assignment.dueAt;
      return dueAt != null && dueAt.isAfter(now);
    }).toList(growable: false)
      ..sort((left, right) => left.dueAt!.compareTo(right.dueAt!));

    if (upcoming.isEmpty) {
      return const [];
    }

    final nearest = upcoming.first;
    final timeLeft = nearest.dueAt!.difference(now);
    if (timeLeft > const Duration(hours: 24)) {
      return const [];
    }

    final hours = timeLeft.inHours.clamp(0, 24);
    return [
      DemoAlert(
        title: 'Deadline inside 24 hours',
        detail:
            '${nearest.name} is due in about $hours hours. Start with the smallest submit-safe checkpoint.',
        severity: DemoAlertSeverity.urgent,
      ),
    ];
  }

  List<DemoAlert> _focusNotifications(
    Duration focusDuration,
    Duration breakThreshold,
  ) {
    if (focusDuration >= breakThreshold) {
      final minutes = breakThreshold.inMinutes;
      return [
        DemoAlert(
          title: 'Laptop break due',
          detail:
              'You have been focused for at least $minutes minutes. Take a 10-minute walk before starting the next task.',
          severity: DemoAlertSeverity.warning,
        ),
      ];
    }
    final softCheckIn = Duration(
      minutes: (breakThreshold.inMinutes * 0.66).round().clamp(10, 120),
    );
    if (focusDuration >= softCheckIn) {
      return [
        const DemoAlert(
          title: 'Focus check-in',
          detail:
              'You are about two-thirds of the way to your break threshold. Stand up, drink water, then choose one next action.',
          severity: DemoAlertSeverity.info,
        ),
      ];
    }
    return const [];
  }

  Duration _focusDuration({
    required DateTime? focusStartedAt,
    required DateTime now,
  }) {
    if (focusStartedAt == null) {
      return Duration.zero;
    }
    final duration = now.difference(focusStartedAt);
    if (duration.isNegative) {
      return Duration.zero;
    }
    return duration;
  }
}
