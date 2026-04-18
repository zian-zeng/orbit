import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';

class StudentNotificationPlan {
  const StudentNotificationPlan({
    required this.generatedAt,
    required this.focusDuration,
    required this.notifications,
    this.notificationsEnabled = true,
    this.quietHoursActive = false,
    this.suppressedCount = 0,
  });

  final DateTime generatedAt;
  final Duration focusDuration;
  final List<DemoAlert> notifications;
  final bool notificationsEnabled;
  final bool quietHoursActive;
  final int suppressedCount;

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
    bool notificationsEnabled = true,
    bool quietHoursEnabled = true,
    int quietHoursStart = 22,
    int quietHoursEnd = 8,
    int sensitivity = 1,
  }) {
    final generatedAt = now ?? DateTime.now();
    final quietActive = quietHoursEnabled &&
        _isQuietHours(
          generatedAt,
          startHour: quietHoursStart,
          endHour: quietHoursEnd,
        );
    final breakThreshold = Duration(
      minutes: focusBreakMinutes.clamp(15, 180),
    );
    final focusDuration = _focusDuration(
      focusStartedAt: focusStartedAt,
      now: generatedAt,
    );
    if (!notificationsEnabled) {
      return StudentNotificationPlan(
        generatedAt: generatedAt,
        focusDuration: focusDuration,
        notifications: const [
          DemoAlert(
            title: 'Notifications paused',
            detail:
                'Student nudges are off. Orbit will still update the monitor when opened.',
            severity: DemoAlertSeverity.info,
          ),
        ],
        notificationsEnabled: false,
        quietHoursActive: quietActive,
      );
    }

    final sensitivityLevel = sensitivity.clamp(0, 2);
    final rawNotifications = <DemoAlert>[
      ..._stressNotifications(report, sensitivityLevel),
      ..._deadlineNotifications(report.snapshot, generatedAt, sensitivityLevel),
      ..._focusNotifications(focusDuration, breakThreshold),
    ];
    final suppressedCount = quietActive
        ? rawNotifications
            .where((alert) => alert.severity != DemoAlertSeverity.urgent)
            .length
        : 0;
    final notifications = quietActive
        ? rawNotifications
            .where((alert) => alert.severity == DemoAlertSeverity.urgent)
            .toList(growable: false)
        : rawNotifications;

    if (notifications.isEmpty) {
      notifications.add(
        DemoAlert(
          title: quietActive ? 'Quiet hours active' : 'No urgent nudges',
          detail: quietActive
              ? 'Non-urgent nudges are muted until quiet hours end. Urgent deadline or stress alerts can still appear.'
              : 'Orbit is watching workload, deadlines, and focus duration. No immediate intervention is needed.',
          severity: DemoAlertSeverity.info,
        ),
      );
    }

    return StudentNotificationPlan(
      generatedAt: generatedAt,
      focusDuration: focusDuration,
      notifications: notifications,
      notificationsEnabled: true,
      quietHoursActive: quietActive,
      suppressedCount: suppressedCount,
    );
  }

  List<DemoAlert> _stressNotifications(
    StudentMonitorReport report,
    int sensitivity,
  ) {
    final score = report.snapshot.stressRiskScore;
    final adjustment = switch (sensitivity) {
      0 => 0.1,
      2 => -0.1,
      _ => 0.0,
    };
    if (score >= 0.72 + adjustment) {
      return const [
        DemoAlert(
          title: 'Stress limit reached',
          detail:
              'The workload risk is high. Ask ORBIT for a 20-minute triage plan before adding new tasks.',
          severity: DemoAlertSeverity.urgent,
        ),
      ];
    }
    if (score >= 0.48 + adjustment) {
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
    int sensitivity,
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
    final deadlineWindow = switch (sensitivity) {
      0 => const Duration(hours: 12),
      2 => const Duration(hours: 36),
      _ => const Duration(hours: 24),
    };
    if (timeLeft > deadlineWindow) {
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

  bool _isQuietHours(
    DateTime now, {
    required int startHour,
    required int endHour,
  }) {
    final start = startHour.clamp(0, 23);
    final end = endHour.clamp(0, 23);
    if (start == end) {
      return false;
    }
    final hour = now.hour;
    if (start < end) {
      return hour >= start && hour < end;
    }
    return hour >= start || hour < end;
  }
}
