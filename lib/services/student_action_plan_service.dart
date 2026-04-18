import 'package:chatbotapp/data_sources/umd_resource_catalog.dart';
import 'package:chatbotapp/services/student_monitor_service.dart';

enum StudentActionUrgency {
  now,
  soon,
  later,
}

class StudentActionPlanStep {
  const StudentActionPlanStep({
    required this.title,
    required this.detail,
    required this.why,
    required this.source,
    required this.toolId,
    required this.urgency,
    required this.prompt,
  });

  final String title;
  final String detail;
  final String why;
  final String source;
  final String toolId;
  final StudentActionUrgency urgency;
  final String prompt;
}

class StudentActionPlan {
  const StudentActionPlan({
    required this.headline,
    required this.summary,
    required this.steps,
    required this.agentHandoff,
    required this.skillPrompt,
  });

  final String headline;
  final String summary;
  final List<StudentActionPlanStep> steps;
  final List<String> agentHandoff;
  final String skillPrompt;
}

class StudentActionPlanService {
  const StudentActionPlanService();

  StudentActionPlan build({
    required StudentMonitorReport report,
    required List<UmdResource> resources,
    required int focusBreakMinutes,
  }) {
    final snapshot = report.snapshot;
    final steps = <StudentActionPlanStep>[];
    final nearestAssignment = snapshot.assignments
        .where((assignment) => assignment.dueAt != null)
        .toList(growable: false)
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final upcomingEvents = snapshot.calendarEvents
        .where((event) => event.start != null)
        .toList(growable: false)
      ..sort((a, b) => a.start!.compareTo(b.start!));

    if (nearestAssignment.isNotEmpty) {
      final assignment = nearestAssignment.first;
      final course = assignment.courseName ?? assignment.courseId;
      steps.add(
        StudentActionPlanStep(
          title: 'Protect $course first',
          detail:
              'Spend 20 focused minutes on ${assignment.name}, then decide whether the next checkpoint is code, notes, or a message to the instructor.',
          why:
              'It is the closest Canvas deadline, so reducing ambiguity here lowers the whole-week stress score.',
          source: 'Canvas',
          toolId: 'canvas_course_scan',
          urgency: StudentActionUrgency.now,
          prompt:
              'Use my Canvas deadlines to make a 20-minute first step for ${assignment.name} in $course.',
        ),
      );
    }

    if (upcomingEvents.isNotEmpty) {
      final event = upcomingEvents.first;
      steps.add(
        StudentActionPlanStep(
          title: 'Schedule around ${event.title}',
          detail:
              'Reserve the smallest open block before or after this event for the protected academic step, instead of adding a new long study session.',
          why:
              'Calendar density is already part of the stress calculation; the plan should fit the day instead of fighting it.',
          source: 'Google Calendar',
          toolId: 'calendar_signal_review',
          urgency: StudentActionUrgency.soon,
          prompt:
              'Use my calendar pressure around ${event.title} to place the next academic step without overloading the day.',
        ),
      );
    }

    if (snapshot.places.isNotEmpty) {
      final place = snapshot.places.first;
      final routeText = snapshot.routes.isEmpty
          ? 'Use the nearest campus route before leaving.'
          : 'Route check: ${snapshot.routes.first.summary}.';
      steps.add(
        StudentActionPlanStep(
          title: 'Fuel stop that respects the profile',
          detail: '${place.name} is the first matched food option. $routeText',
          why:
              'The vegan/plant-based preference is applied automatically, so the student does not need to repeat constraints in the prompt.',
          source: 'Places + profile labels',
          toolId: 'live_places_search',
          urgency: StudentActionUrgency.soon,
          prompt:
              'Find a vegan food stop near my route and keep the recommendation compatible with my current schedule.',
        ),
      );
    }

    if (snapshot.stressRiskScore >= 0.48) {
      steps.add(
        StudentActionPlanStep(
          title: 'Use a $focusBreakMinutes-minute focus boundary',
          detail:
              'Stop the next work block at the configured break threshold, walk for 10 minutes, then restart only the protected task.',
          why:
              'The monitor sees elevated pressure; a smaller loop is safer than pushing through a long laptop session.',
          source: 'Stress monitor',
          toolId: 'stress_report_summarizer',
          urgency: snapshot.stressRiskScore >= 0.72
              ? StudentActionUrgency.now
              : StudentActionUrgency.soon,
          prompt:
              'Help me run a $focusBreakMinutes-minute focus block with a recovery break and one clear restart point.',
        ),
      );
    }

    if (resources.isNotEmpty) {
      final resource = resources.first;
      steps.add(
        StudentActionPlanStep(
          title: 'Keep ${resource.name} ready',
          detail: resource.action,
          why:
              'This is the highest-matching UMD resource for the current labels and request.',
          source: 'UMD resource catalog',
          toolId: 'campus_resource_router',
          urgency: StudentActionUrgency.later,
          prompt:
              'Use ${resource.name} only if the student needs this support path, and explain the next action without over-escalating.',
        ),
      );
    }

    final riskPercent = (snapshot.stressRiskScore * 100).round();
    final headline = snapshot.stressRiskScore >= 0.72
        ? 'Stabilize the next 24 hours for ${report.firstName}'
        : 'Plan the next useful move for ${report.firstName}';
    final agentHandoff = _agentHandoff(steps);

    return StudentActionPlan(
      headline: headline,
      summary:
          '$riskPercent% stress risk, ${snapshot.deadlinesNextSevenDays} upcoming deadlines, ${snapshot.calendarHoursNextSevenDays.toStringAsFixed(1)} calendar hours, and ${snapshot.places.length} food/location matches are converted into ${steps.length} concrete steps.',
      steps: steps.take(5).toList(growable: false),
      agentHandoff: agentHandoff,
      skillPrompt: _skillPrompt(
        report: report,
        steps: steps,
        agentHandoff: agentHandoff,
      ),
    );
  }

  List<String> _agentHandoff(List<StudentActionPlanStep> steps) {
    final agents = <String>{
      if (steps.any((step) => step.toolId == 'canvas_course_scan'))
        'academic_planning_agent',
      if (steps.any((step) => step.toolId == 'calendar_signal_review'))
        'schedule_agent',
      if (steps.any((step) => step.toolId == 'live_places_search'))
        'life_logistics_agent',
      if (steps.any((step) => step.toolId == 'stress_report_summarizer'))
        'stress_monitor_agent',
      if (steps.any((step) => step.toolId == 'campus_resource_router'))
        'campus_resource_agent',
    };
    return agents.toList(growable: false)..sort();
  }

  String _skillPrompt({
    required StudentMonitorReport report,
    required List<StudentActionPlanStep> steps,
    required List<String> agentHandoff,
  }) {
    final stepText = steps.take(5).map((step) => step.title).join(' -> ');
    final agents = agentHandoff.join(', ');
    return 'For ${report.firstName}, use agents [$agents] to execute this student support plan: $stepText. Keep the first response short, ask at most one clarifying question, and do not ignore dietary, schedule, or stress constraints.';
  }
}
