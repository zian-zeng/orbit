import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/models/message.dart';
import 'package:chatbotapp/providers/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;
  late ChatProvider provider;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-hive-test');
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
    provider = ChatProvider();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saveMessagesToDB persists stable routing metadata', () async {
    final messagesBox = await Hive.openBox('chat_messages_test');

    final userMessage = Message(
      messageId: '1',
      chatId: 'chat-1',
      role: Role.user,
      message: StringBuffer('Help me plan my week'),
      imagesUrls: const [],
      timeSent: DateTime(2026, 4, 6),
    );
    final assistantMessage = Message(
      messageId: '2',
      chatId: 'chat-1',
      role: Role.assistant,
      message: StringBuffer('Here is a plan.'),
      imagesUrls: const [],
      timeSent: DateTime(2026, 4, 6),
    );

    await provider.saveMessagesToDB(
      chatID: 'chat-1',
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      messagesBox: messagesBox,
      selectedLabel: 'planning',
      recommendedSkillId: 'workflow.plan_next_steps',
      templateId: 'template.plan_next_steps',
    );

    final saved = Hive.box<ChatHistory>(Constants.chatHistoryBox).get('chat-1');
    expect(saved, isNotNull);
    expect(saved!.selectedLabel, 'planning');
    expect(saved.recommendedSkillId, 'workflow.plan_next_steps');
    expect(saved.templateId, 'template.plan_next_steps');
  });

  test('web storage setup skips the native documents directory', () {
    expect(ChatProvider.resolveHiveDocumentsPath(isWeb: true), isNull);
  });

  test('native storage setup keeps the documents directory path', () {
    expect(
      ChatProvider.resolveHiveDocumentsPath(
        isWeb: false,
        documentsPath: '/tmp/orbit',
      ),
      '/tmp/orbit',
    );
  });
}
