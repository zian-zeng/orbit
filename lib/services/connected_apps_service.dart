import 'package:chatbotapp/agents/orbit_models.dart';
import 'package:chatbotapp/data_sources/integration_config.dart';

enum ConnectedAppStatus {
  connected,
  available,
  demoOnly,
  planned,
}

extension ConnectedAppStatusPresentation on ConnectedAppStatus {
  String get label => switch (this) {
        ConnectedAppStatus.connected => 'Connected',
        ConnectedAppStatus.available => 'Available',
        ConnectedAppStatus.demoOnly => 'Demo mode',
        ConnectedAppStatus.planned => 'Planned',
      };
}

class ConnectedStudentApp {
  const ConnectedStudentApp({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.dataUsed,
    required this.toolIds,
    required this.permissionDecisions,
    required this.nextStep,
  });

  final String id;
  final String name;
  final String description;
  final ConnectedAppStatus status;
  final List<String> dataUsed;
  final List<String> toolIds;
  final List<ToolPermissionDecision> permissionDecisions;
  final String nextStep;

  bool get isConnected => status == ConnectedAppStatus.connected;
}

class ConnectedAppsService {
  const ConnectedAppsService();

  static const OrbitToolPermissionPolicy _permissionPolicy =
      OrbitToolPermissionPolicy();

  List<ConnectedStudentApp> build({
    required IntegrationConfig config,
    required bool allowExternalData,
    required bool preferDemoFixture,
    Iterable<String> labels = const [],
  }) {
    final context = StudentContext(
      profileLabelKeys: labels,
      recentLabelKeys: const [],
      externalLabelKeys: const [],
      selectedLabelKey: null,
      recommendedSkillId: null,
      templateId: null,
      historySummary: '',
      externalContextSummary: '',
      externalStressScore: null,
      hasImages: false,
      message: 'Connected app permission review',
    );
    final liveAllowed = allowExternalData && !preferDemoFixture;

    return [
      _app(
        id: 'student_data_proxy',
        name: 'ORBIT Student Data Proxy',
        description:
            'Desktop/web bridge for OAuth-owned Canvas, Calendar, Maps, Places, and course-planning fetches.',
        status: preferDemoFixture
            ? ConnectedAppStatus.demoOnly
            : liveAllowed && config.hasStudentDataProxy
                ? ConnectedAppStatus.connected
                : ConnectedAppStatus.available,
        dataUsed: const [
          'Canvas deadlines',
          'Google Calendar events',
          'campus routes',
          'places',
          'course/professor signals',
        ],
        toolIds: const [
          'canvas_course_scan',
          'calendar_signal_review',
          'campus_route_planner',
          'live_places_search',
          'course_professor_planner',
        ],
        context: context,
        nextStep: config.hasStudentDataProxy
            ? 'Keep tokens in the proxy and use approval prompts before external fetches.'
            : 'Run backend/student-data-proxy and set STUDENT_DATA_PROXY_URL for the real-data demo.',
      ),
      _app(
        id: 'canvas',
        name: 'UMD ELMS-Canvas',
        description:
            'Reads active courses and upcoming assignments for workload and stress planning.',
        status: preferDemoFixture
            ? ConnectedAppStatus.demoOnly
            : liveAllowed && config.hasCanvas
                ? ConnectedAppStatus.connected
                : ConnectedAppStatus.available,
        dataUsed: const ['active courses', 'assignment names', 'due dates'],
        toolIds: const ['canvas_course_scan'],
        context: context,
        nextStep:
            'Prefer OAuth/proxy storage for real users; direct tokens are only for controlled demos.',
      ),
      _app(
        id: 'google_calendar',
        name: 'Google Calendar',
        description:
            'Reads upcoming events to estimate time pressure and schedule conflicts.',
        status: preferDemoFixture
            ? ConnectedAppStatus.demoOnly
            : liveAllowed && config.hasGoogleCalendar
                ? ConnectedAppStatus.connected
                : ConnectedAppStatus.available,
        dataUsed: const ['event title', 'start/end time', 'location'],
        toolIds: const ['calendar_signal_review', 'schedule_builder'],
        context: context,
        nextStep:
            'Use OAuth consent and show what calendar window ORBIT is reading.',
      ),
      _app(
        id: 'maps_places',
        name: 'Google Maps & Places',
        description:
            'Finds food, study locations, and campus travel times from stored preferences.',
        status: preferDemoFixture
            ? ConnectedAppStatus.demoOnly
            : liveAllowed && config.hasGoogleMaps
                ? ConnectedAppStatus.connected
                : ConnectedAppStatus.available,
        dataUsed: const [
          'place search query',
          'route origin/destination',
          'dietary preference labels',
        ],
        toolIds: const ['live_places_search', 'campus_route_planner'],
        context: context,
        nextStep:
            'Ask before live location searches and keep dietary preferences editable.',
      ),
      _app(
        id: 'planetterp',
        name: 'PlanetTerp',
        description:
            'UMD-specific course, professor, review, and grade signals for registration planning.',
        status: ConnectedAppStatus.available,
        dataUsed: const [
          'course metadata',
          'professor rating',
          'review count',
          'historical GPA',
        ],
        toolIds: const ['course_professor_planner'],
        context: context,
        nextStep:
            'Use live fetch when available, then verify section truth in Testudo.',
      ),
      _app(
        id: 'testudo_umd_io',
        name: 'Testudo / umd.io',
        description:
            'Official course, prerequisite, section, and professor structure for registration truth.',
        status: ConnectedAppStatus.planned,
        dataUsed: const [
          'course availability',
          'section times',
          'prerequisites',
          'GenEd and requirement metadata',
        ],
        toolIds: const ['course_professor_planner', 'schedule_builder'],
        context: context,
        nextStep:
            'Add official course availability before making registration-ready recommendations.',
      ),
      _app(
        id: 'device_activity',
        name: 'Device Activity',
        description:
            'Future private screen-time/focus sensing for break nudges and burnout prevention.',
        status: ConnectedAppStatus.planned,
        dataUsed: const [
          'focus duration',
          'idle time',
          'late-night work pattern'
        ],
        toolIds: const ['stress_report_summarizer', 'recovery_planner'],
        context: context,
        nextStep:
            'Add platform permissions, quiet hours, sensitivity, and local-only retention.',
      ),
      _app(
        id: 'notifications',
        name: 'Local Notifications',
        description:
            'Future OS-level deadline, stress, and movement-break notifications.',
        status: ConnectedAppStatus.planned,
        dataUsed: const ['deadline alerts', 'focus threshold', 'quiet hours'],
        toolIds: const ['recovery_planner'],
        context: context,
        nextStep:
            'Turn the existing notification policy into Android/iOS/desktop local notifications.',
      ),
    ];
  }

  ConnectedStudentApp _app({
    required String id,
    required String name,
    required String description,
    required ConnectedAppStatus status,
    required List<String> dataUsed,
    required List<String> toolIds,
    required StudentContext context,
    required String nextStep,
  }) {
    return ConnectedStudentApp(
      id: id,
      name: name,
      description: description,
      status: status,
      dataUsed: dataUsed,
      toolIds: toolIds,
      permissionDecisions: _permissionPolicy.classify(
        toolIds: toolIds,
        context: context,
      ),
      nextStep: nextStep,
    );
  }
}
