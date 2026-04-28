import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/agent_audit_log_entry.dart';
import 'package:chatbotapp/hive/assistant_feedback_entry.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/monitor_history_entry.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/hive/skill_registry_entry.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
import 'package:chatbotapp/services/demo_bootstrap_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;
  late UserProfileProvider provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-user-profile-test');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatHistoryAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(MonitorHistoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(AssistantFeedbackEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(AgentAuditLogEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(SkillRegistryEntryAdapter());
    }

    await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    await Hive.openBox<UserModel>(Constants.userBox);
    await Hive.openBox<Settings>(Constants.settingsBox);
    await Hive.openBox<MonitorHistoryEntry>(Constants.monitorHistoryBox);
    await Hive.openBox<AssistantFeedbackEntry>(Constants.assistantFeedbackBox);
    await Hive.openBox<AgentAuditLogEntry>(Constants.agentAuditLogBox);
    await Hive.openBox<SkillRegistryEntry>(Constants.skillRegistryBox);
    provider = UserProfileProvider();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('rememberPreferredLabel preserves the full onboarding ranking',
      () async {
    await provider.saveProfile(
      name: 'Taylor',
      email: 'taylor@umd.edu',
      imagePath: '',
      preferredLabelKeys: const [
        'planning',
        'writing',
        'study_help',
        'summarization',
        'image_analysis',
        'wellbeing_checkin',
      ],
    );

    await provider.rememberPreferredLabel('study_help');

    expect(provider.email, 'taylor@umd.edu');
    expect(
      provider.preferredLabelKeys,
      equals([
        'study_help',
        'planning',
        'writing',
        'summarization',
        'image_analysis',
        'wellbeing_checkin',
      ]),
    );
  });

  test('authorizeSession reopens at the guide until setup is complete',
      () async {
    await provider.authorizeSession(
      email: 'taylor@umd.edu',
      authorizationMethod: 'school-email',
    );

    final reloadedProvider = UserProfileProvider();
    await reloadedProvider.loadUser();

    expect(reloadedProvider.isAuthorized, isTrue);
    expect(reloadedProvider.uid, isEmpty);
    expect(reloadedProvider.hasCompletedGuide, isFalse);
    expect(reloadedProvider.hasCompletedOnboarding, isFalse);
    expect(reloadedProvider.shouldShowGuide, isTrue);
    expect(reloadedProvider.shouldShowOnboarding, isFalse);
  });

  test('loadUser recovers to a ready default state when storage access fails',
      () async {
    await Hive.close();

    await provider.loadUser();

    expect(provider.isReady, isTrue);
    expect(provider.shouldShowOnboarding, isFalse);
    expect(provider.hasCompletedOnboarding, isFalse);
    expect(provider.name, 'You');
    expect(provider.preferredLabelKeys, isEmpty);
  });

  test('loadUser skips onboarding for legacy users with prior activity',
      () async {
    await Hive.box<ChatHistory>(Constants.chatHistoryBox).put(
      'chat-1',
      ChatHistory(
        chatId: 'chat-1',
        prompt: 'Hello',
        response: 'Hi',
        imagesUrls: const [],
        timestamp: DateTime(2026, 4, 16),
      ),
    );

    await provider.loadUser();

    expect(provider.isReady, isTrue);
    expect(provider.shouldShowOnboarding, isFalse);
    expect(provider.name, 'You');
  });

  test('loadUser preserves legacy saved profiles through the new startup gates',
      () async {
    await Hive.box<UserModel>(Constants.userBox).add(
      UserModel(
        uid: 'legacy-user',
        name: 'Taylor',
        email: 'taylor@umd.edu',
        image: '',
        preferredLabels: const ['planning', 'writing'],
      ),
    );

    await provider.loadUser();

    expect(provider.isAuthorized, isTrue);
    expect(provider.hasCompletedOnboarding, isTrue);
    expect(provider.hasCompletedGuide, isTrue);
    expect(provider.shouldShowGuide, isFalse);
    expect(provider.shouldShowOnboarding, isFalse);
    expect(provider.email, 'taylor@umd.edu');
  });

  test('imported signals and history enrich routing labels', () async {
    await provider.saveProfile(
      name: 'Taylor',
      imagePath: '',
      preferredLabelKeys: const [
        'writing',
        'planning',
        'study_help',
        'summarization',
        'image_analysis',
        'wellbeing_checkin',
      ],
    );
    await Hive.box<ChatHistory>(Constants.chatHistoryBox).put(
      'chat-1',
      ChatHistory(
        chatId: 'chat-1',
        prompt: 'I am overwhelmed by deadlines and need a plan.',
        response: 'Let us map the week out.',
        imagesUrls: const [],
        timestamp: DateTime(2026, 4, 16),
        selectedLabel: 'wellbeing_checkin',
      ),
    );

    await provider.mergeImportedLabelSignals(
      labelKeys: const [
        'planning',
        'study_help',
        'summarization',
        'writing',
        'image_analysis',
        'wellbeing_checkin',
      ],
      sourceName: 'Google Calendar',
    );

    expect(provider.importedLabelKeys.first, 'planning');
    expect(provider.routingLabelKeys.first, 'planning');
    expect(provider.labelSignalSources, contains('History'));
    expect(provider.labelSignalSources, contains('Google Calendar'));
  });

  test('re-importing the same source replaces stale imported labels', () async {
    await provider.saveProfile(
      name: 'Taylor',
      imagePath: '',
      preferredLabelKeys: const [
        'writing',
        'planning',
        'study_help',
        'summarization',
        'image_analysis',
        'wellbeing_checkin',
      ],
    );

    await provider.mergeImportedLabelSignals(
      labelKeys: const [
        'planning',
        'study_help',
        'summarization',
        'writing',
        'image_analysis',
        'wellbeing_checkin',
      ],
      sourceName: 'Google Calendar',
    );
    await provider.mergeImportedLabelSignals(
      labelKeys: const [
        'wellbeing_checkin',
        'planning',
        'summarization',
        'writing',
        'study_help',
        'image_analysis',
      ],
      sourceName: 'Google Calendar',
    );

    expect(provider.importedLabelKeys.first, 'wellbeing_checkin');
    expect(
      provider.labelSignalSources
          .where((source) => source == 'Google Calendar'),
      hasLength(1),
    );
  });

  test('demo fixture mode imports the polished UMD snapshot', () async {
    await Hive.box<Settings>(Constants.settingsBox).put(
      0,
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
        allowExternalStudentData: true,
        preferDemoFixture: true,
      ),
    );

    final snapshot = await provider.refreshExternalStudentSignals();

    expect(snapshot, isNotNull);
    expect(snapshot!.assignments, isNotEmpty);
    expect(
        snapshot.places.map((place) => place.name), contains('NuVegan Cafe'));
    expect(provider.latestStudentSnapshot, same(snapshot));
    expect(provider.labelSignalSources, contains('UMD Demo Fixture'));
    expect(provider.importedLabelKeys, contains('planning'));
  });

  test('demo login seeds Maya profile and month-long demo state', () async {
    final rejected = await provider.loginAsDemoUser(password: 'wrong');
    expect(rejected, isFalse);

    final accepted = await provider.loginAsDemoUser(
      password: DemoBootstrapService.demoPassword,
    );

    expect(accepted, isTrue);
    expect(provider.name, DemoBootstrapService.demoName);
    expect(provider.email, DemoBootstrapService.demoEmail);
    expect(provider.isAuthorized, isTrue);
    expect(provider.hasCompletedGuide, isTrue);
    expect(provider.hasCompletedOnboarding, isTrue);
    expect(provider.shouldShowGuide, isFalse);
    expect(provider.shouldShowOnboarding, isFalse);
    expect(provider.preferredLabelKeys, contains('vegan'));
    expect(provider.labelSignalSources, contains('UMD Demo Fixture'));
    expect(Hive.box<MonitorHistoryEntry>(Constants.monitorHistoryBox).length,
        greaterThanOrEqualTo(30));
    expect(Hive.box<ChatHistory>(Constants.chatHistoryBox).length,
        greaterThanOrEqualTo(5));
    expect(
      Hive.box<SkillRegistryEntry>(Constants.skillRegistryBox).values,
      isNotEmpty,
    );
    expect(
      Hive.box<AgentAuditLogEntry>(Constants.agentAuditLogBox).values,
      isNotEmpty,
    );
  });
}
