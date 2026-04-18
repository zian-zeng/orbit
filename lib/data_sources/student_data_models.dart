class StudentAssignment {
  const StudentAssignment({
    required this.id,
    required this.courseId,
    required this.name,
    this.courseName,
    this.dueAt,
    this.pointsPossible,
    this.htmlUrl,
  });

  final String id;
  final String courseId;
  final String name;
  final String? courseName;
  final DateTime? dueAt;
  final double? pointsPossible;
  final String? htmlUrl;

  String get summary {
    final dueText = dueAt == null ? 'no due date' : dueAt!.toLocal().toString();
    final courseText = courseName == null ? 'course $courseId' : courseName!;
    return '$name ($courseText, due: $dueText)';
  }
}

class StudentCalendarEvent {
  const StudentCalendarEvent({
    required this.id,
    required this.title,
    this.start,
    this.end,
    this.location,
  });

  final String id;
  final String title;
  final DateTime? start;
  final DateTime? end;
  final String? location;

  Duration get duration {
    final startValue = start;
    final endValue = end;
    if (startValue == null ||
        endValue == null ||
        endValue.isBefore(startValue)) {
      return Duration.zero;
    }
    return endValue.difference(startValue);
  }

  String get summary {
    final startText =
        start == null ? 'unscheduled' : start!.toLocal().toString();
    final locationText =
        location == null || location!.trim().isEmpty ? '' : ' at $location';
    return '$title ($startText$locationText)';
  }
}

class CampusRoute {
  const CampusRoute({
    required this.origin,
    required this.destination,
    required this.travelMode,
    this.duration,
    this.distanceMeters,
  });

  final String origin;
  final String destination;
  final String travelMode;
  final Duration? duration;
  final int? distanceMeters;

  String get summary {
    final durationText = duration == null
        ? 'unknown duration'
        : '${duration!.inMinutes.clamp(1, 999)} min';
    final distanceText = distanceMeters == null
        ? ''
        : ', ${(distanceMeters! / 1609.34).toStringAsFixed(1)} mi';
    return '$origin to $destination by $travelMode: $durationText$distanceText';
  }
}

class CampusPlace {
  const CampusPlace({
    required this.name,
    required this.formattedAddress,
    required this.reason,
    this.googleMapsUri,
    this.servesVegetarianFood,
  });

  final String name;
  final String formattedAddress;
  final String reason;
  final String? googleMapsUri;
  final bool? servesVegetarianFood;

  String get summary {
    final vegetarianText = servesVegetarianFood == true
        ? ' vegetarian-friendly'
        : servesVegetarianFood == false
            ? ' vegetarian status unknown/negative'
            : '';
    return '$name$vegetarianText: $formattedAddress. $reason';
  }
}

class StudentSignalSnapshot {
  const StudentSignalSnapshot({
    required this.fetchedAt,
    required this.assignments,
    required this.calendarEvents,
    required this.routes,
    required this.places,
    required this.sourceNotes,
  });

  factory StudentSignalSnapshot.empty({List<String> sourceNotes = const []}) {
    return StudentSignalSnapshot(
      fetchedAt: DateTime.now(),
      assignments: const [],
      calendarEvents: const [],
      routes: const [],
      places: const [],
      sourceNotes: sourceNotes,
    );
  }

  final DateTime fetchedAt;
  final List<StudentAssignment> assignments;
  final List<StudentCalendarEvent> calendarEvents;
  final List<CampusRoute> routes;
  final List<CampusPlace> places;
  final List<String> sourceNotes;

  int get deadlinesNextSevenDays {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 7));
    return assignments.where((assignment) {
      final dueAt = assignment.dueAt;
      return dueAt != null && dueAt.isAfter(now) && dueAt.isBefore(horizon);
    }).length;
  }

  double get calendarHoursNextSevenDays {
    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 7));
    final total = calendarEvents.where((event) {
      final start = event.start;
      return start != null && start.isAfter(now) && start.isBefore(horizon);
    }).fold<Duration>(
      Duration.zero,
      (total, event) => total + event.duration,
    );
    return total.inMinutes / 60.0;
  }

  double get stressRiskScore {
    final deadlinePressure = (deadlinesNextSevenDays / 6).clamp(0.0, 1.0);
    final calendarPressure = (calendarHoursNextSevenDays / 24).clamp(0.0, 1.0);
    return ((deadlinePressure * 0.58) + (calendarPressure * 0.42))
        .clamp(0.0, 1.0);
  }

  List<String> get inferredLabelKeys {
    final labels = <String>{};
    if (assignments.isNotEmpty) {
      labels.add('study_help');
      labels.add('planning');
      labels.add('academic_planning');
    }
    if (deadlinesNextSevenDays >= 4 || stressRiskScore >= 0.55) {
      labels.add('wellbeing_checkin');
      labels.add('stress_sensitive');
    }
    if (calendarEvents.isNotEmpty) {
      labels.add('planning');
      labels.add('calendar_density');
    }
    if (routes.isNotEmpty) {
      labels.add('planning');
      labels.add('campus_navigation');
    }
    if (places.isNotEmpty) {
      labels.add('life_logistics');
      labels.add('planning');
    }
    return labels.toList(growable: false)..sort();
  }

  String get agentContextSummary {
    final lines = <String>[
      'External data snapshot: ${fetchedAt.toLocal()}',
      'Upcoming Canvas assignments: ${assignments.length}',
      'Calendar events: ${calendarEvents.length}',
      'Deadlines next 7 days: $deadlinesNextSevenDays',
      'Calendar hours next 7 days: ${calendarHoursNextSevenDays.toStringAsFixed(1)}',
      'Computed stress risk: ${stressRiskScore.toStringAsFixed(2)}',
      if (assignments.isNotEmpty) 'Nearest assignments:',
      ...assignments.take(5).map((assignment) => '- ${assignment.summary}'),
      if (calendarEvents.isNotEmpty) 'Upcoming calendar events:',
      ...calendarEvents.take(5).map((event) => '- ${event.summary}'),
      if (routes.isNotEmpty) 'Campus routes:',
      ...routes.take(3).map((route) => '- ${route.summary}'),
      if (places.isNotEmpty) 'Live place search:',
      ...places.take(5).map((place) => '- ${place.summary}'),
      if (sourceNotes.isNotEmpty) 'Source notes:',
      ...sourceNotes.map((note) => '- $note'),
    ];
    return lines.join('\n');
  }
}
