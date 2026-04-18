import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/providers/user_profile_provider.dart';
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

    await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
    await Hive.openBox<UserModel>(Constants.userBox);
    await Hive.openBox<Settings>(Constants.settingsBox);
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
}
