import 'package:flutter/material.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/settings.dart';

enum AppThemeMode {
  auto,
  light,
  dark,
}

class SettingsProvider extends ChangeNotifier {
  AppThemeMode _appThemeMode = AppThemeMode.auto;
  bool _enableHaptics = true;
  bool _saveChatHistory = true;
  bool _autoScroll = true;
  bool _enableVoiceInput = true;
  bool _reduceMotion = false;
  bool _sendWithEnter = true;
  bool _autoFocusComposer = false;
  bool _showStarterPrompts = true;
  int _focusBreakMinutes = 45;
  bool _allowExternalStudentData = false;
  bool _preferDemoFixture = false;
  bool _enableStudentNotifications = true;
  bool _enableQuietHours = true;
  int _quietHoursStart = 22;
  int _quietHoursEnd = 8;
  int _notificationSensitivity = 1;

  AppThemeMode get appThemeMode => _appThemeMode;

  ThemeMode get themeMode => switch (_appThemeMode) {
        AppThemeMode.auto => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  bool get isDarkMode => _appThemeMode == AppThemeMode.dark;

  bool get enableHaptics => _enableHaptics;

  bool get saveChatHistory => _saveChatHistory;

  bool get autoScroll => _autoScroll;

  bool get enableVoiceInput => _enableVoiceInput;

  bool get reduceMotion => _reduceMotion;

  bool get sendWithEnter => _sendWithEnter;

  bool get autoFocusComposer => _autoFocusComposer;

  bool get showStarterPrompts => _showStarterPrompts;

  int get focusBreakMinutes => _focusBreakMinutes;

  bool get allowExternalStudentData => _allowExternalStudentData;

  bool get preferDemoFixture => _preferDemoFixture;

  bool get allowLiveStudentData =>
      allowExternalStudentData && !preferDemoFixture;

  bool get enableStudentNotifications => _enableStudentNotifications;

  bool get enableQuietHours => _enableQuietHours;

  int get quietHoursStart => _quietHoursStart;

  int get quietHoursEnd => _quietHoursEnd;

  int get notificationSensitivity => _notificationSensitivity;

  String get notificationSensitivityLabel => switch (notificationSensitivity) {
        0 => 'Low',
        2 => 'High',
        _ => 'Balanced',
      };

  AppThemeMode _themeModeFromSettings(Settings settings) {
    final storedIndex = settings.themeModeIndex;
    if (storedIndex >= 0 && storedIndex < AppThemeMode.values.length) {
      return AppThemeMode.values[storedIndex];
    }
    return settings.isDarkTheme ? AppThemeMode.dark : AppThemeMode.light;
  }

  // get the saved settings from box
  void getSavedSettings() {
    final settingsBox = Boxes.getSettings();

    // check is the settings box is open
    if (settingsBox.isNotEmpty) {
      // get the settings
      final settings = settingsBox.getAt(0);
      _appThemeMode = _themeModeFromSettings(settings!);
      _enableHaptics = settings.enableHaptics;
      _saveChatHistory = settings.saveChatHistory;
      _autoScroll = settings.autoScroll;
      _enableVoiceInput = settings.enableVoiceInput;
      _reduceMotion = settings.reduceMotion;
      _sendWithEnter = settings.sendWithEnter;
      _autoFocusComposer = settings.autoFocusComposer;
      _showStarterPrompts = settings.showStarterPrompts;
      _focusBreakMinutes = settings.focusBreakMinutes.clamp(15, 180);
      _allowExternalStudentData = settings.allowExternalStudentData;
      _preferDemoFixture = settings.preferDemoFixture;
      _enableStudentNotifications = settings.enableStudentNotifications;
      _enableQuietHours = settings.enableQuietHours;
      _quietHoursStart = settings.quietHoursStart.clamp(0, 23);
      _quietHoursEnd = settings.quietHoursEnd.clamp(0, 23);
      _notificationSensitivity = settings.notificationSensitivity.clamp(0, 2);
    }
  }

  void reloadSavedSettings() {
    getSavedSettings();
    notifyListeners();
  }

  Settings _currentSettings(Settings? settings) {
    return settings ??
        Settings(
          isDarkTheme: isDarkMode,
          enableHaptics: enableHaptics,
          saveChatHistory: saveChatHistory,
          autoScroll: autoScroll,
          enableVoiceInput: enableVoiceInput,
          reduceMotion: reduceMotion,
          confirmBeforeDeleting: true,
          themeModeIndex: appThemeMode.index,
          sendWithEnter: sendWithEnter,
          autoFocusComposer: autoFocusComposer,
          showStarterPrompts: showStarterPrompts,
          focusBreakMinutes: focusBreakMinutes,
          allowExternalStudentData: allowExternalStudentData,
          preferDemoFixture: preferDemoFixture,
          enableStudentNotifications: enableStudentNotifications,
          enableQuietHours: enableQuietHours,
          quietHoursStart: quietHoursStart,
          quietHoursEnd: quietHoursEnd,
          notificationSensitivity: notificationSensitivity,
        );
  }

  void _saveSettings(Settings settings) {
    final settingsBox = Boxes.getSettings();
    if (settingsBox.isEmpty) {
      settingsBox.put(0, settings);
    } else {
      settingsBox.put(0, settings);
    }
  }

  void setThemeMode({
    required AppThemeMode value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.isDarkTheme = value == AppThemeMode.dark;
    current.themeModeIndex = value.index;
    _saveSettings(current);

    _appThemeMode = value;
    notifyListeners();
  }

  void toggleHaptics({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.enableHaptics = value;
    _saveSettings(current);

    _enableHaptics = value;
    notifyListeners();
  }

  void toggleSaveChatHistory({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.saveChatHistory = value;
    _saveSettings(current);

    _saveChatHistory = value;
    notifyListeners();
  }

  void toggleAutoScroll({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.autoScroll = value;
    _saveSettings(current);

    _autoScroll = value;
    notifyListeners();
  }

  void toggleVoiceInput({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.enableVoiceInput = value;
    _saveSettings(current);

    _enableVoiceInput = value;
    notifyListeners();
  }

  void toggleReduceMotion({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.reduceMotion = value;
    _saveSettings(current);

    _reduceMotion = value;
    notifyListeners();
  }

  void toggleSendWithEnter({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.sendWithEnter = value;
    _saveSettings(current);

    _sendWithEnter = value;
    notifyListeners();
  }

  void toggleAutoFocusComposer({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.autoFocusComposer = value;
    _saveSettings(current);

    _autoFocusComposer = value;
    notifyListeners();
  }

  void toggleShowStarterPrompts({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.showStarterPrompts = value;
    _saveSettings(current);

    _showStarterPrompts = value;
    notifyListeners();
  }

  void setFocusBreakMinutes({
    required int value,
    Settings? settings,
  }) {
    final normalized = value.clamp(15, 180);
    final current = _currentSettings(settings);
    current.focusBreakMinutes = normalized;
    _saveSettings(current);

    _focusBreakMinutes = normalized;
    notifyListeners();
  }

  void toggleExternalStudentData({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.allowExternalStudentData = value;
    _saveSettings(current);

    _allowExternalStudentData = value;
    notifyListeners();
  }

  void togglePreferDemoFixture({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.preferDemoFixture = value;
    _saveSettings(current);

    _preferDemoFixture = value;
    notifyListeners();
  }

  void toggleStudentNotifications({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.enableStudentNotifications = value;
    _saveSettings(current);

    _enableStudentNotifications = value;
    notifyListeners();
  }

  void toggleQuietHours({
    required bool value,
    Settings? settings,
  }) {
    final current = _currentSettings(settings);
    current.enableQuietHours = value;
    _saveSettings(current);

    _enableQuietHours = value;
    notifyListeners();
  }

  void setQuietHours({
    required int start,
    required int end,
    Settings? settings,
  }) {
    final normalizedStart = start.clamp(0, 23);
    final normalizedEnd = end.clamp(0, 23);
    final current = _currentSettings(settings);
    current.quietHoursStart = normalizedStart;
    current.quietHoursEnd = normalizedEnd;
    _saveSettings(current);

    _quietHoursStart = normalizedStart;
    _quietHoursEnd = normalizedEnd;
    notifyListeners();
  }

  void setNotificationSensitivity({
    required int value,
    Settings? settings,
  }) {
    final normalized = value.clamp(0, 2);
    final current = _currentSettings(settings);
    current.notificationSensitivity = normalized;
    _saveSettings(current);

    _notificationSensitivity = normalized;
    notifyListeners();
  }
}
