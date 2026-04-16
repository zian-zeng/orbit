import 'package:flutter_test/flutter_test.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/providers/voice_input_provider.dart';
import 'package:chatbotapp/screens/chat_screen.dart';
import 'package:chatbotapp/screens/home_screen.dart';
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
    required bool hasCompletedOnboarding,
    String name = 'You',
    List<String> preferredLabelKeys = const [],
  })  : _isReady = isReady,
        _hasCompletedOnboarding = hasCompletedOnboarding,
        _name = name,
        _preferredLabelKeys = preferredLabelKeys;

  bool _isReady;
  bool _hasCompletedOnboarding;
  String _name;
  List<String> _preferredLabelKeys;

  @override
  bool get isReady => _isReady;

  @override
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  @override
  bool get shouldShowOnboarding => !_hasCompletedOnboarding;

  @override
  String get uid => _hasCompletedOnboarding ? 'test-user' : '';

  @override
  String get name => _name;

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
  Future<void> saveProfile({
    required String name,
    required String imagePath,
    List<String>? preferredLabelKeys,
    List<String>? importedLabelKeys,
    List<String>? importedSources,
    List<String>? importedSourceRankings,
  }) async {
    _name = name.trim().isEmpty ? 'You' : name.trim();
    _preferredLabelKeys = preferredLabelKeys ?? _preferredLabelKeys;
    _hasCompletedOnboarding = true;
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

void main() {
  testWidgets('Chat screen renders empty state', (WidgetTester tester) async {
    await pumpChatScreen(tester);

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Map out a plan'), findsOneWidget);
    expect(find.text('Draft a polished reply'), findsOneWidget);
  });

  testWidgets('Selecting a recommendation prefills the composer', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.text('Draft a polished reply'));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      textField.controller?.text,
      'Help me draft a clear, polished message about: ',
    );
  });

  testWidgets('Label override reshapes recommendations', (
    WidgetTester tester,
  ) async {
    await pumpChatScreen(tester);

    await tester.tap(find.text('Image analysis'));
    await tester.pumpAndSettle();

    expect(find.text('Analyze an image'), findsOneWidget);
  });

  testWidgets('Home screen shows onboarding before chat for first-run users', (
    WidgetTester tester,
  ) async {
    await pumpHomeScreen(
      tester,
      userProfileProvider: TestUserProfileProvider(
        isReady: true,
        hasCompletedOnboarding: false,
      ),
    );

    expect(find.text('Welcome to Orbit'), findsOneWidget);
    expect(find.text('How can I help?'), findsNothing);
  });

  testWidgets('Completing onboarding unlocks chat',
      (WidgetTester tester) async {
    final userProfileProvider = TestUserProfileProvider(
      isReady: true,
      hasCompletedOnboarding: false,
    );

    await pumpHomeScreen(
      tester,
      userProfileProvider: userProfileProvider,
    );

    await tester.enterText(find.byType(TextField).first, 'Taylor');
    await tester.ensureVisible(find.text('Feel less overwhelmed'));
    await tester.tap(find.text('Feel less overwhelmed'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Steady support'));
    await tester.tap(find.text('Steady support'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Stress spiral'));
    await tester.tap(find.text('Stress spiral'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      userProfileProvider.preferredLabelKeys,
      equals([
        'wellbeing_checkin',
        'planning',
        'summarization',
        'writing',
        'study_help',
        'image_analysis',
      ]),
    );
    expect(find.text('How can I help?'), findsOneWidget);
    expect(find.text('Reflect and regroup'), findsOneWidget);
    expect(find.text('Welcome to Orbit'), findsNothing);
  });
}
