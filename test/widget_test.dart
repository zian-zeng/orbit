import 'package:flutter_test/flutter_test.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/providers/voice_input_provider.dart';
import 'package:chatbotapp/screens/chat_screen.dart';
import 'package:chatbotapp/screens/connected_apps_screen.dart';
import 'package:chatbotapp/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> pumpChatScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => VoiceInputProvider()),
      ],
      child: MaterialApp(
        home: const ChatScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    ),
  );
}

class TestUserProfileProvider extends UserProfileProvider {
  TestUserProfileProvider({
    required bool isReady,
    bool isAuthorized = false,
    bool hasCompletedGuide = false,
    required bool hasCompletedOnboarding,
    String name = 'You',
    String email = '',
    List<String> preferredLabelKeys = const [],
  })  : _isReady = isReady,
        _isAuthorized = isAuthorized,
        _hasCompletedGuide = hasCompletedGuide,
        _hasCompletedOnboarding = hasCompletedOnboarding,
        _name = name,
        _email = email,
        _preferredLabelKeys = preferredLabelKeys;

  bool _isReady;
  bool _isAuthorized;
  bool _hasCompletedGuide;
  bool _hasCompletedOnboarding;
  String _name;
  String _email;
  List<String> _preferredLabelKeys;

  @override
  bool get isReady => _isReady;

  @override
  bool get isAuthorized => _isAuthorized;

  @override
  bool get hasCompletedGuide => _hasCompletedGuide;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  @override
  bool get shouldShowOnboarding =>
      _isAuthorized && _hasCompletedGuide && !_hasCompletedOnboarding;

  @override
  bool get shouldShowGuide => _isAuthorized && !_hasCompletedGuide;

  @override
  String get uid => _hasCompletedOnboarding ? 'test-user' : '';

  @override
  String get name => _name;

  @override
  String get email => _email;

  @override
  String get firstName => name.split(' ').first;

  @override
  String get imagePath => '';

  @override
  List<String> get preferredLabelKeys =>
      List<String>.unmodifiable(_preferredLabelKeys);

  @override
  List<String> get routingLabelKeys =>
      List<String>.unmodifiable(_preferredLabelKeys);

  @override
  Future<void> loadUser() async {
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<void> authorizeSession({
    required String email,
    required String authorizationMethod,
  }) async {
    _email = email;
    _isAuthorized = true;
    _hasCompletedGuide = false;
    _hasCompletedOnboarding = false;
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<void> completeGuide() async {
    _isAuthorized = true;
    _hasCompletedGuide = true;
    _isReady = true;
    notifyListeners();
  }

  @override
  Future<void> saveProfile({
    required String name,
    required String imagePath,
    String? email,
    bool? isAuthorized,
    bool? hasCompletedOnboarding,
    bool? hasCompletedGuide,
    String? authorizationMethod,
    String? authorizedAtIso,
    List<String>? preferredLabelKeys,
    List<String>? importedLabelKeys,
    List<String>? importedSources,
    List<String>? importedSourceRankings,
  }) async {
    _name = name.trim().isEmpty ? 'You' : name.trim();
    _email = email ?? _email;
    _isAuthorized = isAuthorized ?? _isAuthorized;
    _hasCompletedGuide = hasCompletedGuide ?? _hasCompletedGuide;
    _preferredLabelKeys = preferredLabelKeys ?? _preferredLabelKeys;
    _hasCompletedOnboarding = hasCompletedOnboarding ?? true;
    _isReady = true;
    notifyListeners();
  }
}

Future<void> pumpHomeScreen(
  WidgetTester tester, {
  required UserProfileProvider userProfileProvider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<UserProfileProvider>.value(
          value: userProfileProvider,
        ),
        ChangeNotifierProvider(create: (_) => VoiceInputProvider()),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    ),
  );
}

Future<void> pumpConnectedAppsScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
      ],
      child: MaterialApp(
        home: const ConnectedAppsScreen(),
        theme: ThemeData(useMaterial3: true),
      ),
    ),
  );
}

void main() {
  testWidgets('Chat screen renders empty state', (WidgetTester tester) async {
    await pumpChatScreen(tester);

    expect(find.text('Orbit'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Map out a plan'), findsOneWidget);
    expect(find.text('Draft a polished reply'), findsOneWidget);
    expect(find.text('Tap to prefill'), findsNothing);
  });

  testWidgets('Selecting a recommendation prefills the composer', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.ensureVisible(find.text('Draft a polished reply'));
    await tester.tap(find.text('Draft a polished reply'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      textField.controller?.text,
      'Help me draft a clear, polished message about: ',
    );
    expect(find.text('Draft a polished reply'), findsNothing);
  });

  testWidgets('Label override reshapes recommendations', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.ensureVisible(find.text('Image analysis'));
    await tester.tap(find.text('Image analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Analyze an image'), findsOneWidget);
  });

  testWidgets('Business demo path can load the UMD scenario prompt', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.byTooltip('Demo status'));
    await tester.pumpAndSettle();

    expect(find.text('UMD Demo Path'), findsOneWidget);
    expect(find.text('Next Best Action Plan'), findsOneWidget);
    expect(find.text('Personalized Food Search'), findsOneWidget);
    expect(find.text('Next Semester Plan'), findsOneWidget);
    expect(find.text('Notification Center'), findsOneWidget);

    await tester.ensureVisible(find.text('Simulate 45m laptop block'));
    await tester.tap(find.text('Simulate 45m laptop block'));
    await tester.pumpAndSettle();

    expect(find.text('Laptop break due'), findsOneWidget);

    await tester.ensureVisible(find.text('Use this prompt in chat'));
    await tester.tap(find.text('Use this prompt in chat'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, contains('I am vegan'));
    expect(textField.controller?.text, contains('Canvas deadlines'));
  });

  testWidgets('Intelligence dashboard opens from chat header', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.byTooltip('Intelligence dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Intelligence Dashboard'), findsOneWidget);
    expect(find.text('Evaluation Readiness'), findsOneWidget);
    expect(find.text('Skill Registry'), findsOneWidget);
    expect(find.text('Feedback Signal'), findsOneWidget);
    expect(find.text('Agent Audit Trail'), findsOneWidget);
  });

  testWidgets('Course planner opens and loads a plan into chat', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.byTooltip('Course planner'));
    await tester.pumpAndSettle();

    expect(find.text('Course Planner'), findsOneWidget);
    expect(find.text('Balanced Plan'), findsOneWidget);
    expect(find.text('Professor Comparison'), findsOneWidget);
    expect(find.text('Fetch PlanetTerp'), findsOneWidget);
    expect(
      find.text('CMSC216 - Introduction to Computer Systems'),
      findsOneWidget,
    );

    await tester.tap(find.text('Use in chat'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(textField.controller?.text, contains('next semester courses'));
    expect(textField.controller?.text, contains('PlanetTerp'));
  });

  testWidgets('Connected apps screen shows data sources and permissions', (
    WidgetTester tester,
  ) async {
    await pumpConnectedAppsScreen(tester);

    expect(find.text('Connected Apps'), findsOneWidget);
    expect(find.text('ORBIT Student Data Proxy'), findsOneWidget);
    expect(find.text('UMD ELMS-Canvas'), findsOneWidget);
    expect(find.text('PlanetTerp'), findsOneWidget);
    expect(find.textContaining('course_professor_planner'), findsWidgets);
    expect(find.textContaining('requires approval'), findsWidgets);
  });

  testWidgets('Home screen shows authorization before onboarding for new users',
      (WidgetTester tester) async {
    await pumpHomeScreen(
      tester,
      userProfileProvider: TestUserProfileProvider(
        isReady: true,
        isAuthorized: false,
        hasCompletedOnboarding: false,
      ),
    );

    expect(find.text('Authorize Orbit'), findsOneWidget);
    expect(
      find.text('Welcome to Orbit'),
      findsNothing,
    );
  });

  testWidgets('Authorization continues into the startup guide',
      (WidgetTester tester) async {
    final userProfileProvider = TestUserProfileProvider(
      isReady: true,
      isAuthorized: false,
      hasCompletedOnboarding: false,
    );

    await pumpHomeScreen(
      tester,
      userProfileProvider: userProfileProvider,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'taylor@umd.edu',
    );
    final continueToGuideButton = find.widgetWithText(
      FilledButton,
      'Continue to guide',
    );
    await tester.ensureVisible(continueToGuideButton);
    await tester.tap(continueToGuideButton);
    await tester.pumpAndSettle();

    expect(userProfileProvider.isAuthorized, isTrue);
    expect(userProfileProvider.hasCompletedGuide, isFalse);
    expect(find.text('How Orbit works'), findsOneWidget);
    expect(find.text('Continue to setup'), findsOneWidget);
  });

  testWidgets('Home screen shows onboarding after guide completion',
      (WidgetTester tester) async {
    await pumpHomeScreen(
      tester,
      userProfileProvider: TestUserProfileProvider(
        isReady: true,
        isAuthorized: true,
        hasCompletedGuide: true,
        hasCompletedOnboarding: false,
        email: 'taylor@umd.edu',
      ),
    );

    expect(find.text('Finish your support profile'), findsOneWidget);
    expect(find.text('Authorize Orbit'), findsNothing);
    expect(find.text('How Orbit works'), findsNothing);
  });

  testWidgets('Onboarding options render as full-width selection boxes',
      (WidgetTester tester) async {
    await pumpHomeScreen(
      tester,
      userProfileProvider: TestUserProfileProvider(
        isReady: true,
        isAuthorized: true,
        hasCompletedGuide: true,
        hasCompletedOnboarding: false,
        email: 'taylor@umd.edu',
      ),
    );

    final optionFinder =
        find.byKey(const ValueKey('option-primary_goal-stay_organized'));
    expect(optionFinder, findsOneWidget);
    expect(tester.getSize(optionFinder).width, greaterThan(500));
    expect(
      find.descendant(
        of: optionFinder,
        matching: find.byIcon(CupertinoIcons.chevron_right),
      ),
      findsNothing,
    );
  });

  testWidgets('Completing onboarding unlocks chat',
      (WidgetTester tester) async {
    final userProfileProvider = TestUserProfileProvider(
      isReady: true,
      isAuthorized: false,
      hasCompletedOnboarding: false,
    );

    await pumpHomeScreen(
      tester,
      userProfileProvider: userProfileProvider,
    );

    await tester.enterText(find.byType(TextField).first, 'taylor@umd.edu');
    final continueToGuideButton = find.widgetWithText(
      FilledButton,
      'Continue to guide',
    );
    await tester.ensureVisible(continueToGuideButton);
    await tester.tap(continueToGuideButton);
    await tester.pumpAndSettle();

    final continueToSetupButton = find.widgetWithText(
      FilledButton,
      'Continue to setup',
    );
    await tester.ensureVisible(continueToSetupButton);
    await tester.tap(continueToSetupButton);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Taylor');
    await _tapOnboardingOption(tester, 'student_stage', 'undergrad_upper');
    await _tapOnboardingOption(tester, 'major_area', 'cs_engineering');
    await _tapOnboardingOption(tester, 'age_context', 'traditional_age');
    await _tapOnboardingOption(tester, 'enrollment_work', 'student_working');
    await _tapOnboardingOption(
        tester, 'international_status', 'multilingual_student');
    await _tapOnboardingOption(
        tester, 'first_language', 'first_language_other');
    await _tapOnboardingOption(
        tester, 'background_support', 'accessibility_or_health');
    await _tapOnboardingOption(tester, 'subject_pressure', 'coding_lab_stress');
    await _tapOnboardingOption(
        tester, 'academic_strength', 'strength_visual_hands_on');
    await _tapOnboardingOption(
        tester, 'course_life_need', 'job_internship_work');
    await _tapOnboardingOption(tester, 'primary_goal', 'feel_less_overwhelmed');
    await _tapOnboardingOption(tester, 'response_style', 'steady_support');
    await _tapOnboardingOption(tester, 'blocker', 'stress_spiral');
    await _tapOnboardingOption(tester, 'semester_load', 'heavy_course_load');
    await _tapOnboardingOption(tester, 'deadline_pattern', 'overplan');
    await _tapOnboardingOption(tester, 'class_support', 'practice_plan');
    await _tapOnboardingOption(tester, 'writing_need', 'draft_from_scratch');
    await _tapOnboardingOption(tester, 'reading_volume', 'many_readings');
    await _tapOnboardingOption(tester, 'image_need', 'sometimes_images');
    await _tapOnboardingOption(tester, 'stress_pattern', 'when_behind');
    await _tapOnboardingOption(tester, 'energy_pattern', 'long_laptop_blocks');
    await _tapOnboardingOption(tester, 'schedule_source', 'google_calendar');
    await _tapOnboardingOption(tester, 'calendar_density', 'very_crowded');
    await _tapOnboardingOption(tester, 'canvas_habit', 'canvas_daily');
    await _tapOnboardingOption(tester, 'commute', 'commuter');
    await _tapOnboardingOption(tester, 'dining_preference', 'vegan_food');
    await _tapOnboardingOption(
        tester, 'accessibility_need', 'adhd_or_focus_support');
    await _tapOnboardingOption(tester, 'career_focus', 'career_active');
    await _tapOnboardingOption(
        tester, 'campus_confidence', 'somewhat_confident');
    await _tapOnboardingOption(tester, 'notification_style', 'break_nudges');
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      userProfileProvider.preferredLabelKeys,
      containsAll([
        'wellbeing_checkin',
        'planning',
        'summarization',
        'writing',
        'study_help',
        'image_analysis',
        'vegan',
        'plant_based',
        'movement_breaks',
        'google_calendar',
        'working_student',
        'language_support',
        'mental_health_support',
        'career_builder',
      ]),
    );
    expect(userProfileProvider.email, 'taylor@umd.edu');
    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Support pulse'), findsOneWidget);
    expect(find.text('Use a question or action to draft the next prompt.'),
        findsOneWidget);
    expect(find.text('Reflect and regroup'), findsOneWidget);
    expect(find.text('Finish your support profile'), findsNothing);
  });

  testWidgets('Guide can be reopened from the chat workspace',
      (WidgetTester tester) async {
    await pumpHomeScreen(
      tester,
      userProfileProvider: TestUserProfileProvider(
        isReady: true,
        isAuthorized: true,
        hasCompletedGuide: true,
        hasCompletedOnboarding: true,
        email: 'taylor@umd.edu',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Guide'), findsOneWidget);

    await tester.tap(find.byTooltip('Guide'));
    await tester.pumpAndSettle();

    expect(find.text('How Orbit works'), findsOneWidget);
    expect(find.text('Continue to chat'), findsOneWidget);
  });
}

Future<void> _tapOnboardingOption(
  WidgetTester tester,
  String questionId,
  String optionId,
) async {
  final finder = find.byKey(ValueKey('option-$questionId-$optionId'));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
