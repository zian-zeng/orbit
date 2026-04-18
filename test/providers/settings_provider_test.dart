import 'dart:io';

import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/settings.dart';
import 'package:chatbotapp/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('orbit-settings-test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    await Hive.openBox<Settings>(Constants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('persists custom focus break threshold', () {
    final provider = SettingsProvider();

    provider.setFocusBreakMinutes(value: 45);
    expect(provider.focusBreakMinutes, 45);

    provider.setFocusBreakMinutes(value: 5);
    expect(provider.focusBreakMinutes, 15);

    provider.setFocusBreakMinutes(value: 200);
    expect(provider.focusBreakMinutes, 180);

    final reloaded = SettingsProvider()..getSavedSettings();
    expect(reloaded.focusBreakMinutes, 180);
  });

  test('persists external student data consent', () {
    final provider = SettingsProvider();

    provider.toggleExternalStudentData(value: true);
    expect(provider.allowExternalStudentData, isTrue);

    final reloaded = SettingsProvider()..getSavedSettings();
    expect(reloaded.allowExternalStudentData, isTrue);

    reloaded.toggleExternalStudentData(value: false);
    expect(reloaded.allowExternalStudentData, isFalse);
  });
}
