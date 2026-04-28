import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:hive/hive.dart';

class DemoBootstrapService {
  const DemoBootstrapService();

  static const String demoUid = 'demo-maya-chen';
  static const String demoName = 'Maya Chen';
  static const String demoEmail = 'maya.chen@umd.edu';
  static const String demoPassword = '12345';

  static const List<String> demoPreferredLabels = [
    'planning',
    'study_help',
    'wellbeing_checkin',
    'writing',
    'summarization',
    'image_analysis',
    'vegan',
    'plant_based',
    'academic_planning',
    'stress_sensitive',
    'life_logistics',
    'campus_navigation',
    'google_calendar',
    'canvas',
    'career_builder',
    'campus_resources',
  ];

  Future<void> bootstrapMayaChen({DateTime? now}) async {
    final timestamp = now ?? DateTime.now();
    final scenario = OrbitBusinessDemoScenario.veganUmdStudent();
    await _seedUser(timestamp);
    await _seedSettings();
    await _seedChatHistory(timestamp, scenario);
    await _seedMonitorHistory(timestamp, scenario);
    await _seedSkillRegistry(timestamp);
    await _seedAuditLog(timestamp, scenario);
    await _seedFeedback(timestamp);
  }

  Future<void> _seedUser(DateTime timestamp) async {
    if (!Hive.isBoxOpen(Constants.userBox)) {
      return;
    }

    final user = UserModel(
      uid: demoUid,
      name: demoName,
      image: '',
      email: demoEmail,
      isAuthorized: true,
      hasCompletedGuide: true,
      hasCompletedOnboarding: true,
      authorizationMethod: 'demo-login',
      authorizedAtIso: timestamp.toUtc().toIso8601String(),
      preferredLabels: demoPreferredLabels,
      importedLabels: const [
        'academic_planning',
        'calendar_density',
        'campus_navigation',
        'life_logistics',
        'planning',
        'stress_sensitive',
        'study_help',
        'wellbeing_checkin',
      ],
      importedSources: const ['UMD Demo Fixture'],
      importedSourceRankings: const [
        'UMD Demo Fixture::planning,study_help,wellbeing_checkin,academic_planning,calendar_density,campus_navigation,life_logistics,stress_sensitive',
      ],
    );

    final box = Boxes.getUser();
    if (box.isEmpty) {
      await box.add(user);
    } else {
      await box.putAt(0, user);
    }
  }

  Future<void> _seedSettings() async {
    if (!Hive.isBoxOpen(Constants.settingsBox)) {
      return;
    }

    final box = Boxes.getSettings();
    final current = box.isNotEmpty ? box.getAt(0) : null;
    final settings = current ??
        Settings(
          isDarkTheme: false,
          enableHaptics: true,
          saveChatHistory: true,
          autoScroll: true,
          enableVoiceInput: true,
          reduceMotion: false,
          confirmBeforeDeleting: true,
          themeModeIndex: 0,
          sendWithEnter: true,
          autoFocusComposer: false,
          showStarterPrompts: true,
        );

    settings.allowExternalStudentData = false;
    settings.preferDemoFixture = true;
    settings.saveChatHistory = true;
    settings.showStarterPrompts = true;
    settings.focusBreakMinutes = 45;
    settings.enableStudentNotifications = true;
    await box.put(0, settings);
  }

  Future<void> _seedChatHistory(
    DateTime now,
    OrbitBusinessDemoScenario scenario,
  ) async {
    if (!Hive.isBoxOpen(Constants.chatHistoryBox)) {
      return;
    }

    final box = Boxes.getChatHistory();
    final entries = [
      ChatHistory(
        chatId: 'demo-maya-history-1',
        prompt:
            'I am vegan and usually between IRB and McKeldin. Can you remember that when suggesting food or study spots?',
        response:
            'Yes. I saved vegan food, plant-based options, and the IRB to McKeldin walking corridor as planning constraints.\n\nFor future food or study suggestions, I will prefer places that are reachable without making you cross campus twice, and I will avoid suggesting a meal stop that breaks your vegan preference.\n\nORBIT trace: Memory capture -> Preference labels -> Campus navigation -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 29, hours: 3)),
        selectedLabel: 'life_logistics',
        recommendedSkillId: 'life_logistics_campus_router',
        templateId: 'demo_preference_capture',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-2',
        prompt:
            'CMSC216 projects make me anxious when I do not know the first step.',
        response:
            'That makes sense. For CMSC216, I will avoid giving you a giant plan first. I will start by asking what the project is asking for, then turn it into one checkpoint you can finish in 20 minutes.\n\nA good default first move is: open the README, identify the expected input/output, and write one tiny test or comment for the first function. After that, we can decide whether the real blocker is syntax, debugging, or understanding the assignment.\n\nORBIT trace: Chat history lookup -> Academic planning -> Stress monitoring -> Study coach -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 24, hours: 6)),
        selectedLabel: 'wellbeing_checkin',
        recommendedSkillId: 'support_wellbeing_checkin_high_router',
        templateId: 'stress_reset',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-3',
        prompt:
            'I work late shifts twice a week, so long study plans usually fail.',
        response:
            'I will treat late shifts as real constraints, not as something you are supposed to power through. On work nights, I will bias the plan toward short review, setup, or admin tasks. On non-work nights, I will place the harder thinking work earlier and keep a recovery buffer afterward.\n\nFor Maya, a realistic plan is better than a heroic one: 25 minutes before work can still count if it prevents the task from becoming scary tomorrow.\n\nORBIT trace: Calendar signals -> Work-shift constraint solver -> Stress monitoring -> Planning agent -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 20, hours: 2)),
        selectedLabel: 'planning',
        recommendedSkillId: 'support_planning_elevated_router',
        templateId: 'schedule_builder',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-4',
        prompt:
            'Can you help me email my TA? I need to ask about the CMSC216 project without sounding panicked.',
        response:
            'Absolutely. Here is a calm version that asks for help without over-explaining:\n\nSubject: Question about starting the CMSC216 project\n\nHi [TA Name],\n\nI am reviewing the project requirements and want to make sure I am starting in the right direction. I understand the main goal, but I am unsure about the first implementation step. Would you be able to point me toward the part of the spec I should focus on first, or confirm whether my starting plan makes sense?\n\nThank you,\nMaya\n\nI can also help turn this into a shorter version if you want it to feel more casual.\n\nORBIT trace: Writing agent -> Academic planning -> Stress-sensitive tone check -> Email action draft -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 16, hours: 5)),
        selectedLabel: 'writing',
        recommendedSkillId: 'academic_email_helper',
        templateId: 'ta_email_draft',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-5',
        prompt:
            'I have CMSC216, a work shift, and a club meeting tomorrow. Can you help me make a plan that does not collapse?',
        response:
            'Yes. I would plan tomorrow around energy, not just time.\n\n1. Before class: 20 minutes to read the CMSC216 spec and write down the one confusing part.\n2. Between class and work: food first, then one small implementation checkpoint.\n3. After work: no heavy coding. Send the TA question if needed, pack for tomorrow, and stop.\n\nThis keeps the day from depending on a late-night burst of discipline. I would also add a calendar block called CMSC216 first checkpoint, not finish project, because the smaller label is easier to start.\n\nORBIT trace: Calendar signals -> Canvas deadline scan -> Work-shift constraint solver -> Stress monitoring -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 13, hours: 4)),
        selectedLabel: 'planning',
        recommendedSkillId: 'support_planning_elevated_router',
        templateId: 'collapse_resistant_day',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-6',
        prompt:
            'I need career fair prep, but not at the expense of this week\'s deadlines.',
        response:
            'We can keep career prep useful without letting it eat the week. I would make the target one concrete artifact: a 45-second intro and one revised resume bullet for your strongest project.\n\nThen I would protect the course deadlines by placing career prep after the nearest Canvas checkpoint, not before it. That way career prep feels like progress instead of avoidance.\n\nORBIT trace: Canvas deadline scan -> Career agent -> Planning agent -> Stress monitoring -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 8, hours: 1)),
        selectedLabel: 'planning',
        recommendedSkillId: 'career_timeline_builder',
        templateId: 'career_balance',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-7',
        prompt:
            'What should I eat near IRB before going to McKeldin? I want vegan food but not a huge detour.',
        response:
            'Given your vegan preference and the IRB to McKeldin route, I would choose NuVegan Cafe if you have enough time, or a closer campus option if your next block starts soon.\n\nThe key is not just finding vegan food; it is keeping the route compatible with your calendar. Would you like me to quickly map the walking route from IRB to NuVegan Cafe? It is about a 12-minute walk.\n\nORBIT trace: Preference labels -> Google Places demo connector -> Campus route planner -> Calendar pressure check -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 6, hours: 3)),
        selectedLabel: 'campus_navigation',
        recommendedSkillId: 'life_logistics_campus_router',
        templateId: 'vegan_route_food',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-8',
        prompt:
            'I am stressed because my report page says my stress is high this week. What does that actually mean?',
        response:
            'It means your recent signals are asking for a smaller, kinder plan. It does not mean you are failing.\n\nFor this week, ORBIT is seeing a mix of higher deadline pressure, denser calendar blocks, and less recovery room. I would respond by choosing fewer commitments, making the first academic step more concrete, and protecting one meal or rest block before the next push.\n\nThe recommendation is not do less forever. It is do the right-sized next thing today so tomorrow has more room.\n\nORBIT trace: Student report summarizer -> Stress monitoring -> Advisor voice -> Planning agent -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 4, hours: 7)),
        selectedLabel: 'wellbeing_checkin',
        recommendedSkillId: 'student_report_advisor',
        templateId: 'report_reflection',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-9',
        prompt:
            'Can you create a study block and remind me to send the TA email?',
        response:
            'Yes. For the demo, I would add a calendar block called CMSC216 first checkpoint for 4:30 PM to 5:15 PM, then add a reminder to send the TA email after the checkpoint.\n\nI would also keep the invite note simple: Start with the smallest project checkpoint, then send the TA question if the blocker is still unclear.\n\nCalendar event prepared. Email reminder prepared.\n\nORBIT trace: Calendar action planner -> Email action planner -> Academic planning -> Stress monitoring -> Response synthesizer (demo fixture)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 3, hours: 8)),
        selectedLabel: 'google_calendar',
        recommendedSkillId: 'calendar_email_demo_actions',
        templateId: 'calendar_email_action',
      ),
      ChatHistory(
        chatId: 'demo-maya-history-10',
        prompt: scenario.demoPrompt,
        response:
            'I would handle this as one coordinated plan, not separate advice.\n\nFirst, food: choose a vegan stop that fits the IRB to McKeldin path, so eating does not become another decision tax. If time is tight, pick the closest reliable option; if you have room, NuVegan is a good fit.\n\nSecond, coursework: open the nearest Canvas deadline and define a 20-minute checkpoint. Do not try to finish the whole assignment before you know the first blocker.\n\nThird, stress pacing: put a real stop time on the plan. If the checkpoint reveals confusion, send the TA email instead of staying stuck alone.\n\nWould you like me to quickly map the walking route from IRB to NuVegan Cafe? I can also add the CMSC216 checkpoint to Google Calendar and prepare the TA email reminder.\n\nORBIT trace: History lookup -> Canvas deadline scan -> Calendar pressure check -> Stress report summarizer -> Google Places demo connector -> Campus route planner -> Email/calendar action planner -> Response synthesizer (Gemini first, Gemma fallback ready)',
        imagesUrls: const [],
        timestamp: now.subtract(const Duration(days: 2, hours: 5)),
        selectedLabel: 'planning',
        recommendedSkillId: 'runtime.skill.planning.demo',
        templateId: 'umd_demo_path',
      ),
    ];

    for (final entry in entries) {
      await box.put(entry.chatId, entry);
      await _seedChatMessages(entry);
    }
  }

  Future<void> _seedChatMessages(ChatHistory entry) async {
    final box =
        await Hive.openBox('${Constants.chatMessagesBox}${entry.chatId}');
    await box.clear();
    await box.add(
      Message(
        messageId: '0',
        chatId: entry.chatId,
        role: Role.user,
        message: StringBuffer(entry.prompt),
        imagesUrls: entry.imagesUrls,
        timeSent: entry.timestamp,
      ).toMap(),
    );
    await box.add(
      Message(
        messageId: '1',
        chatId: entry.chatId,
        role: Role.assistant,
        message: StringBuffer(entry.response),
        imagesUrls: const [],
        timeSent: entry.timestamp.add(const Duration(seconds: 1)),
      ).toMap(),
    );
    await box.close();
  }

  Future<void> _seedMonitorHistory(
    DateTime now,
    OrbitBusinessDemoScenario scenario,
  ) async {
    if (!Hive.isBoxOpen(Constants.monitorHistoryBox)) {
      return;
    }

    final box = Boxes.getMonitorHistory();
    final labels = scenario.preferenceLabels;
    const stressPattern = [
      0.34,
      0.39,
      0.44,
      0.51,
      0.47,
      0.42,
      0.36,
      0.48,
      0.56,
      0.62,
      0.58,
      0.53,
      0.41,
      0.38,
      0.46,
      0.59,
      0.67,
      0.73,
      0.69,
      0.55,
      0.43,
      0.50,
      0.64,
      0.78,
      0.82,
      0.74,
      0.61,
      0.48,
      0.57,
      0.66,
    ];

    for (var index = 0; index < stressPattern.length; index += 1) {
      final createdAt = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: stressPattern.length - index - 1));
      final stress = stressPattern[index];
      final deadlines = stress >= 0.72
          ? 5
          : stress >= 0.58
              ? 4
              : stress >= 0.46
                  ? 3
                  : 2;
      final calendarHours = 2.5 + (stress * 7.2) + (index % 3) * 0.35;
      final id =
          '${demoEmail.toLowerCase()}|demo|${createdAt.toIso8601String()}';
      await box.put(
        id,
        MonitorHistoryEntry(
          id: id,
          createdAt: createdAt,
          studentEmail: demoEmail,
          source: 'demo',
          stressScore: stress,
          deadlines: deadlines,
          calendarHours: calendarHours,
          placeCount: 2,
          routeCount: 1,
          labels: labels,
          sourceNote:
              'Seeded Maya Chen demo checkpoint for month-long monitor trend.',
        ),
      );
    }
  }

  Future<void> _seedSkillRegistry(DateTime now) async {
    if (!Hive.isBoxOpen(Constants.skillRegistryBox)) {
      return;
    }

    final entry = SkillRegistryEntry(
      id: 'support_planning_high_router|v1',
      skillId: 'support_planning_high_router',
      version: 1,
      createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      title: 'Planning + Wellbeing Support Router',
      summary:
          'Demo skill generated from Maya Chen\'s labels, chat history, and UMD workload fixture.',
      systemPrompt:
          'Use Maya Chen\'s planning, vegan, campus navigation, Canvas, Google Calendar, and stress-sensitive labels to choose one clarifying question, one concrete next step, and the right agent tools.',
      starterPrompt:
          'Use profile labels, month-long monitor history, recent chat history, and the current UMD demo query to coordinate a personalized response.',
      toolIds: const [
        'chat_history_lookup',
        'calendar_signal_review',
        'canvas_course_scan',
        'stress_report_summarizer',
        'live_places_search',
        'campus_route_planner',
      ],
      toolLabels: const [
        'History lookup',
        'Calendar signals',
        'Canvas scan',
        'Stress report',
        'Places search',
        'Campus route planner',
      ],
      toolReasons: const [
        'Ground the plan in Maya\'s previous constraints.',
        'Check calendar pressure before recommending a schedule.',
        'Prioritize the nearest Canvas deadline.',
        'Keep the first step small when stress is high.',
        'Apply vegan and location preferences to food search.',
        'Keep the food stop compatible with campus movement.',
      ],
      sourceLabels: demoPreferredLabels,
      stressBand: 'high',
      isActive: true,
    );

    await Boxes.getSkillRegistry().put(entry.id, entry);
  }

  Future<void> _seedAuditLog(
    DateTime now,
    OrbitBusinessDemoScenario scenario,
  ) async {
    if (!Hive.isBoxOpen(Constants.agentAuditLogBox)) {
      return;
    }

    final entry = AgentAuditLogEntry(
      id: 'demo-maya-chat|assistant-demo-audit',
      chatId: 'demo-maya-chat',
      messageId: 'assistant-demo-audit',
      createdAt: now.subtract(const Duration(hours: 18)),
      activatedRoles: const [
        'Workflow controller',
        'Academic planning',
        'Stress monitoring',
        'Campus resources',
        'Life logistics',
        'Response synthesizer',
      ],
      skillIds: const [
        'runtime.skill.planning.umd_demo_path',
        'agent.academic_planning.priority_map',
        'agent.stress_monitoring.risk_check',
        'agent.campus_resources.connector',
        'agent.life_logistics.constraint_solver',
      ],
      toolNames: const [
        'calendar_signal_review',
        'campus_route_planner',
        'canvas_course_scan',
        'chat_history_lookup',
        'live_places_search',
        'stress_report_summarizer',
      ],
      dataSources: const [
        'Canvas',
        'Google Calendar',
        'Google Places',
        'Google Routes',
        'History',
      ],
      labelKeys: demoPreferredLabels,
      usedLocalModel: false,
      modelName: 'demo-fixture',
      fallbackReason: '',
      latencyMs: 420,
      userMessagePreview: scenario.demoPrompt,
      responsePreview:
          'Coordinated Canvas deadline triage, calendar pressure, vegan food search, campus route, and stress-aware pacing.',
    );

    await Boxes.getAgentAuditLog().put(entry.id, entry);
  }

  Future<void> _seedFeedback(DateTime now) async {
    if (!Hive.isBoxOpen(Constants.assistantFeedbackBox)) {
      return;
    }

    final entry = AssistantFeedbackEntry(
      id: 'demo-maya-chat|assistant-demo-audit',
      chatId: 'demo-maya-chat',
      messageId: 'assistant-demo-audit',
      feedbackType: 'helpful',
      createdAt: now.subtract(const Duration(hours: 17)),
      responsePreview:
          'The response balanced food, schedule, deadlines, and stress pacing.',
      agentTrace:
          'Workflow controller -> Academic planning -> Stress monitoring -> Campus resources -> Life logistics -> Response synthesizer',
    );
    await Boxes.getAssistantFeedback().put(entry.id, entry);
  }
}
