import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/data_sources/umd_resource_catalog.dart';

abstract class OrbitAgent {
  const OrbitAgent();

  OrbitAgentRole get role;
  String get skillId;

  bool shouldActivate(StudentContext context);

  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  });

  bool containsAny(String text, Iterable<String> keywords) {
    final normalized = text.toLowerCase();
    return keywords.any(normalized.contains);
  }
}

class AcademicPlanningAgent extends OrbitAgent {
  const AcademicPlanningAgent();

  @override
  OrbitAgentRole get role => OrbitAgentRole.academicPlanning;

  @override
  String get skillId => 'agent.academic_planning.priority_map';

  @override
  bool shouldActivate(StudentContext context) {
    return context.hasAnyLabel(const [
          'academic_planning',
          'planning',
          'study_help',
          'summarization',
        ]) ||
        containsAny(context.message, const [
          'deadline',
          'assignment',
          'exam',
          'quiz',
          'project',
          'study',
          'homework',
          'canvas',
          'course',
          'courses',
          'class',
          'classes',
          'professor',
          'semester',
          'registration',
          'testudo',
        ]);
  }

  @override
  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    final text = request.message.toLowerCase();
    final deadlineSignal = containsAny(text, const [
      'deadline',
      'due',
      'assignment',
      'exam',
      'quiz',
      'midterm',
      'final',
    ]);
    final courseSelectionSignal = containsAny(text, const [
      'course',
      'courses',
      'class',
      'classes',
      'professor',
      'semester',
      'registration',
      'testudo',
      'planetterp',
    ]);

    return SkillResult(
      skillId: skillId,
      role: role,
      title: 'Priority and study plan',
      summary: deadlineSignal
          ? 'The request has explicit workload or deadline signals. Prioritize by due date, grade impact, and effort uncertainty.'
          : 'The request benefits from breaking work into a visible next-action plan.',
      recommendations: const [
        'Ask for missing Canvas deadlines or course names before inventing dates.',
        'Create a short triage table: task, due window, effort, next action.',
        'Prefer a 24-hour plan first, then a weekly plan if the user asks.',
        'For course selection, compare Testudo availability, prerequisite fit, PlanetTerp grade/review signals, and anecdotal workload notes before recommending a professor.',
        'Do not optimize only for easy grades; balance learning fit, stress load, graduation requirements, and schedule constraints.',
      ],
      confidence: deadlineSignal || courseSelectionSignal ? 0.86 : 0.68,
    );
  }
}

class StressMonitoringAgent extends OrbitAgent {
  const StressMonitoringAgent();

  @override
  OrbitAgentRole get role => OrbitAgentRole.stressMonitoring;

  @override
  String get skillId => 'agent.stress_monitoring.risk_check';

  @override
  bool shouldActivate(StudentContext context) {
    return context.stressEstimate >= 0.34 ||
        context.hasAnyLabel(const ['wellbeing_checkin', 'stress_sensitive']) ||
        containsAny(context.message, const [
          'stress',
          'stressed',
          'overwhelmed',
          'anxious',
          'burnout',
          'tired',
          'exhausted',
          'panic',
        ]);
  }

  @override
  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    final elevated = context.stressBand == 'elevated';

    return SkillResult(
      skillId: skillId,
      role: role,
      title: 'Stress-aware pacing',
      summary:
          'Estimated stress band is ${context.stressBand}. Use supportive pacing and avoid pretending to diagnose mental health.',
      recommendations: [
        'Offer one concrete next step before adding more options.',
        'Suggest a short reset interval when workload language is intense.',
        if (elevated)
          'If the user expresses immediate danger or self-harm, recommend emergency or campus crisis support.',
      ],
      confidence: elevated ? 0.82 : 0.62,
    );
  }
}

class CampusResourceAgent extends OrbitAgent {
  const CampusResourceAgent();

  static const UmdResourceCatalog _catalog = UmdResourceCatalog();

  @override
  OrbitAgentRole get role => OrbitAgentRole.campusResources;

  @override
  String get skillId => 'agent.campus_resources.connector';

  @override
  bool shouldActivate(StudentContext context) {
    return context.hasAnyLabel(const [
          'campus_resources',
          'international_student',
          'incoming_student',
        ]) ||
        containsAny(context.message, const [
          'campus',
          'advisor',
          'office',
          'resource',
          'umd',
          'canvas',
          'calendar',
          'food',
          'dining',
          'vegan',
          'vegetarian',
          'halal',
          'kosher',
          'gluten',
          'allergy',
          'housing',
          'transport',
          'commute',
        ]);
  }

  @override
  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    final resources = _catalog.match(
      message: request.message,
      labels: context.allLabels,
    );
    final resourceLines = resources
        .map((resource) => resource.agentBrief)
        .toList(growable: false);

    return SkillResult(
      skillId: skillId,
      role: role,
      title: 'Resource connection',
      summary:
          'Campus and institutional data should be treated as retrieval-backed. Use the UMD-first local resource catalog when live campus search is unavailable.',
      recommendations: [
        ...resourceLines,
        'Separate known user-provided facts from placeholders for Canvas, calendar, or campus resources.',
        'When useful, ask the user to paste the relevant deadline, event, or resource text.',
        'Prefer routing the user to the right category of support instead of naming unsupported real-time offices.',
      ],
      confidence: 0.58,
    );
  }
}

class CareerStrategyAgent extends OrbitAgent {
  const CareerStrategyAgent();

  @override
  OrbitAgentRole get role => OrbitAgentRole.careerStrategy;

  @override
  String get skillId => 'agent.career_strategy.timeline';

  @override
  bool shouldActivate(StudentContext context) {
    return context.hasAnyLabel(const ['career_builder', 'pre_internship']) ||
        containsAny(context.message, const [
          'career',
          'internship',
          'resume',
          'interview',
          'job',
          'network',
        ]);
  }

  @override
  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    return const SkillResult(
      skillId: 'agent.career_strategy.timeline',
      role: OrbitAgentRole.careerStrategy,
      title: 'Career timeline',
      summary:
          'Career support should connect current academic load to a realistic recruiting or portfolio timeline.',
      recommendations: [
        'Convert vague career goals into a near-term artifact: resume bullet, application list, outreach message, or project milestone.',
        'Balance career work against current coursework instead of assuming unlimited time.',
      ],
      confidence: 0.64,
    );
  }
}

class LifeLogisticsAgent extends OrbitAgent {
  const LifeLogisticsAgent();

  @override
  OrbitAgentRole get role => OrbitAgentRole.lifeLogistics;

  @override
  String get skillId => 'agent.life_logistics.tradeoff';

  @override
  bool shouldActivate(StudentContext context) {
    return context.hasAnyLabel(const ['life_logistics', 'financial_stress']) ||
        containsAny(context.message, const [
          'budget',
          'money',
          'rent',
          'meal',
          'food',
          'dining',
          'housing',
          'transport',
          'commute',
        ]);
  }

  @override
  SkillResult run({
    required OrbitAgentRequest request,
    required StudentContext context,
  }) {
    return const SkillResult(
      skillId: 'agent.life_logistics.tradeoff',
      role: OrbitAgentRole.lifeLogistics,
      title: 'Life logistics',
      summary:
          'The response should account for practical constraints like money, food, transport, time, and energy.',
      recommendations: [
        'Frame choices as tradeoffs with one low-friction action.',
        'Avoid financial certainty; ask for budget numbers when specific calculations matter.',
      ],
      confidence: 0.6,
    );
  }
}
