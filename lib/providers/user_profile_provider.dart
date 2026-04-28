import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/data_sources/student_context_aggregator.dart';
import 'package:chatbotapp/data_sources/student_data_models.dart';
import 'package:chatbotapp/demo/orbit_business_demo_scenario.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:chatbotapp/services/demo_bootstrap_service.dart';
import 'package:chatbotapp/services/label_enrichment_service.dart';
import 'package:chatbotapp/services/support_intelligence_service.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class UserProfileProvider extends ChangeNotifier {
  static const LabelEnrichmentService _labelEnrichmentService =
      LabelEnrichmentService();
  static const SupportIntelligenceService _supportIntelligenceService =
      SupportIntelligenceService();
  static const DemoBootstrapService _demoBootstrapService =
      DemoBootstrapService();
  final StudentContextAggregator _contextAggregator =
      StudentContextAggregator();

  String _uid = '';
  String _name = 'You';
  String _email = '';
  String _imagePath = '';
  bool _isAuthorized = false;
  bool _hasCompletedOnboarding = false;
  bool _hasCompletedGuide = false;
  String _authorizationMethod = '';
  String _authorizedAtIso = '';
  List<String> _preferredLabelKeys = [];
  List<String> _importedLabelKeys = [];
  Map<String, List<String>> _importedSourceRankings = {};
  List<String> _importedSourceNames = [];
  List<String> _routingLabelKeys = [];
  List<String> _labelSignalSources = [];
  StudentSignalSnapshot? _latestStudentSnapshot;
  bool _isRefreshingExternalSignals = false;
  bool _isReady = false;

  String get uid => _uid;
  String get name => _name.trim().isEmpty ? 'You' : _name.trim();
  String get email => _email.trim();
  String get firstName => name.split(' ').first;
  String get imagePath => _imagePath;
  bool get isAuthorized => _isAuthorized;
  bool get isReady => _isReady;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasCompletedGuide => _hasCompletedGuide;
  bool get shouldShowOnboarding =>
      _isAuthorized && _hasCompletedGuide && !_hasCompletedOnboarding;
  bool get shouldShowGuide => _isAuthorized && !_hasCompletedGuide;
  String get authorizationMethod => _authorizationMethod;
  String get authorizedAtIso => _authorizedAtIso;
  List<String> get preferredLabelKeys =>
      List<String>.unmodifiable(_preferredLabelKeys);
  List<String> get importedLabelKeys =>
      List<String>.unmodifiable(_importedLabelKeys);
  List<String> get routingLabelKeys => _routingLabelKeys.isNotEmpty
      ? List<String>.unmodifiable(_routingLabelKeys)
      : List<String>.unmodifiable(_preferredLabelKeys);
  List<String> get labelSignalSources =>
      List<String>.unmodifiable(_labelSignalSources);
  StudentSignalSnapshot? get latestStudentSnapshot => _latestStudentSnapshot;
  bool get isRefreshingExternalSignals => _isRefreshingExternalSignals;
  bool get hasImage => _imagePath.trim().isNotEmpty;
  static const String demoEmail = DemoBootstrapService.demoEmail;
  static const String demoPassword = DemoBootstrapService.demoPassword;
  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Y';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _resetProfile({
    required bool isAuthorized,
    required bool hasCompletedOnboarding,
    required bool hasCompletedGuide,
  }) {
    _uid = '';
    _name = 'You';
    _email = '';
    _imagePath = '';
    _isAuthorized = isAuthorized;
    _hasCompletedOnboarding = hasCompletedOnboarding;
    _hasCompletedGuide = hasCompletedGuide;
    _authorizationMethod = '';
    _authorizedAtIso = '';
    _preferredLabelKeys = [];
    _importedLabelKeys = [];
    _importedSourceRankings = {};
    _importedSourceNames = [];
    _routingLabelKeys = [];
    _labelSignalSources = [];
    _latestStudentSnapshot = null;
    _isRefreshingExternalSignals = false;
  }

  bool _hasLegacyActivity() {
    return Boxes.getChatHistory().isNotEmpty || Boxes.getSettings().isNotEmpty;
  }

  List<String> _serializeImportedSourceRankings() {
    return _importedSourceRankings.entries
        .map((entry) => '${entry.key}::${entry.value.join(',')}')
        .toList(growable: false);
  }

  Map<String, List<String>> _deserializeImportedSourceRankings(
    List<String> serialized,
  ) {
    final snapshots = <String, List<String>>{};
    for (final item in serialized) {
      final parts = item.split('::');
      if (parts.length != 2 || parts.first.trim().isEmpty) {
        continue;
      }
      final labels = parts.last
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      if (labels.isEmpty) {
        continue;
      }
      snapshots[parts.first] = labels;
    }
    return snapshots;
  }

  void _refreshRoutingLabels() {
    try {
      _importedLabelKeys = _labelEnrichmentService.mergeImportedSourceRankings(
        _importedSourceRankings.values,
      );
      _importedSourceNames =
          _importedSourceRankings.keys.toList(growable: false);
      final history = Boxes.getChatHistory().values.toList(growable: false);
      final snapshot = _labelEnrichmentService.buildSnapshot(
        preferredLabelKeys: _preferredLabelKeys,
        importedLabelKeys: _importedLabelKeys,
        importedSources: _importedSourceNames,
        history: history,
      );
      _routingLabelKeys = snapshot.rankedLabels
          .map((label) => label.storageKey)
          .toList(growable: false);
      _labelSignalSources = snapshot.sourceBadges;
    } catch (_) {
      _routingLabelKeys = List<String>.from(_preferredLabelKeys);
    }
  }

  Future<void> loadUser() async {
    try {
      final userBox = Boxes.getUser();
      final hasLegacyActivity = _hasLegacyActivity();
      if (userBox.isEmpty) {
        _resetProfile(
          isAuthorized: hasLegacyActivity,
          hasCompletedOnboarding: hasLegacyActivity,
          hasCompletedGuide: hasLegacyActivity,
        );
        _refreshRoutingLabels();
        return;
      }

      final user = userBox.getAt(0);
      if (user == null) {
        _resetProfile(
          isAuthorized: hasLegacyActivity,
          hasCompletedOnboarding: hasLegacyActivity,
          hasCompletedGuide: hasLegacyActivity,
        );
        _refreshRoutingLabels();
        return;
      }

      final legacyAuthorized =
          user.uid.trim().isNotEmpty || user.email.trim().isNotEmpty;
      final looksLikeLegacyCompletedProfile = user.uid.trim().isNotEmpty &&
          !user.isAuthorized &&
          user.authorizationMethod.trim().isEmpty &&
          user.authorizedAtIso.trim().isEmpty;
      _uid = user.uid;
      _name = user.name;
      _email = user.email;
      _imagePath = user.image;
      _isAuthorized = user.isAuthorized || legacyAuthorized;
      _hasCompletedOnboarding =
          user.hasCompletedOnboarding || looksLikeLegacyCompletedProfile;
      _hasCompletedGuide = user.hasCompletedGuide || _hasCompletedOnboarding;
      _authorizationMethod = user.authorizationMethod;
      _authorizedAtIso = user.authorizedAtIso;
      _preferredLabelKeys = List<String>.from(user.preferredLabels);
      _importedSourceRankings = _deserializeImportedSourceRankings(
        user.importedSourceRankings,
      );
      if (_importedSourceRankings.isEmpty && user.importedSources.isNotEmpty) {
        _importedSourceRankings = {
          user.importedSources.first: List<String>.from(user.importedLabels),
        };
      }
      _refreshRoutingLabels();
    } catch (error, stackTrace) {
      _resetProfile(
        isAuthorized: false,
        hasCompletedOnboarding: false,
        hasCompletedGuide: false,
      );
      _refreshRoutingLabels();
      log(
        'Failed to load user profile',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isReady = true;
      notifyListeners();
    }
  }

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
    final trimmedName = name.trim().isEmpty ? 'You' : name.trim();
    final resolvedHasCompletedOnboarding =
        hasCompletedOnboarding ?? _hasCompletedOnboarding;
    final userBox = Boxes.getUser();
    final user = UserModel(
      uid: resolvedHasCompletedOnboarding
          ? (_uid.isEmpty ? const Uuid().v4() : _uid)
          : _uid,
      name: trimmedName,
      image: imagePath,
      email: email ?? _email,
      isAuthorized: isAuthorized ?? _isAuthorized,
      hasCompletedOnboarding: resolvedHasCompletedOnboarding,
      hasCompletedGuide: hasCompletedGuide ?? _hasCompletedGuide,
      authorizationMethod: authorizationMethod ?? _authorizationMethod,
      authorizedAtIso: authorizedAtIso ?? _authorizedAtIso,
      preferredLabels: preferredLabelKeys ?? _preferredLabelKeys,
      importedLabels: importedLabelKeys ?? _importedLabelKeys,
      importedSources: importedSources ?? _importedSourceNames,
      importedSourceRankings:
          importedSourceRankings ?? _serializeImportedSourceRankings(),
    );

    if (userBox.isEmpty) {
      await userBox.add(user);
    } else {
      await userBox.putAt(0, user);
    }

    _uid = user.uid;
    _name = user.name;
    _email = user.email;
    _imagePath = user.image;
    _isAuthorized = user.isAuthorized;
    _hasCompletedOnboarding = user.hasCompletedOnboarding;
    _hasCompletedGuide = user.hasCompletedGuide;
    _authorizationMethod = user.authorizationMethod;
    _authorizedAtIso = user.authorizedAtIso;
    _preferredLabelKeys = List<String>.from(user.preferredLabels);
    _importedSourceRankings = _deserializeImportedSourceRankings(
      user.importedSourceRankings,
    );
    if (_importedSourceRankings.isEmpty && user.importedSources.isNotEmpty) {
      _importedSourceRankings = {
        user.importedSources.first: List<String>.from(user.importedLabels),
      };
    }
    _refreshRoutingLabels();
    _isReady = true;
    notifyListeners();
  }

  Future<void> authorizeSession({
    required String email,
    required String authorizationMethod,
  }) async {
    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      email: email.trim(),
      isAuthorized: true,
      hasCompletedGuide: false,
      hasCompletedOnboarding: false,
      authorizationMethod: authorizationMethod,
      authorizedAtIso: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<bool> loginAsDemoUser({required String password}) async {
    if (password.trim() != DemoBootstrapService.demoPassword) {
      return false;
    }

    await resetDemoUser();
    return true;
  }

  Future<void> resetDemoUser() async {
    await _demoBootstrapService.bootstrapMayaChen();
    await loadUser();
  }

  Future<void> completeGuide() async {
    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      isAuthorized: true,
      hasCompletedGuide: true,
    );
  }

  Future<void> rememberPreferredLabel(String labelKey) async {
    if (labelKey.trim().isEmpty) {
      return;
    }

    final updated = <String>[
      labelKey,
      ..._preferredLabelKeys.where((existing) => existing != labelKey),
    ];

    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      preferredLabelKeys: updated,
    );
  }

  Future<void> refreshEnrichedLabels() async {
    _refreshRoutingLabels();
    notifyListeners();
  }

  SupportIntelligenceBundle? buildSupportIntelligence({
    List<String> recentLabelKeys = const [],
  }) {
    final history = Hive.isBoxOpen(Constants.chatHistoryBox)
        ? Boxes.getChatHistory().values.toList(growable: false)
        : const <ChatHistory>[];
    return _supportIntelligenceService.buildBundle(
      routingLabelKeys: routingLabelKeys,
      recentLabelKeys: recentLabelKeys,
      labelSignalSources: labelSignalSources,
      history: history,
    );
  }

  Future<void> mergeImportedLabelSignals({
    required List<String> labelKeys,
    required String sourceName,
  }) async {
    if (labelKeys.isEmpty) {
      _importedSourceRankings.remove(sourceName);
    } else {
      _importedSourceRankings[sourceName] = List<String>.from(labelKeys);
    }
    _refreshRoutingLabels();
    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      importedLabelKeys: _importedLabelKeys,
      importedSources: _importedSourceNames,
      importedSourceRankings: _serializeImportedSourceRankings(),
    );
  }

  Future<void> clearImportedLabelSignals() async {
    _importedSourceRankings = {};
    _refreshRoutingLabels();
    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      importedLabelKeys: const [],
      importedSources: const [],
      importedSourceRankings: const [],
    );
  }

  Future<StudentSignalSnapshot?> refreshExternalStudentSignals({
    bool forceRefresh = false,
    String taskText = '',
    Iterable<String>? preferenceTags,
  }) async {
    if (_isRefreshingExternalSignals) {
      return _latestStudentSnapshot;
    }
    _isRefreshingExternalSignals = true;
    notifyListeners();
    try {
      if (_preferDemoFixture()) {
        final scenario = OrbitBusinessDemoScenario.veganUmdStudent();
        _latestStudentSnapshot = scenario.snapshot;
        await mergeImportedLabelSignals(
          labelKeys: scenario.snapshot.inferredLabelKeys,
          sourceName: 'UMD Demo Fixture',
        );
        return scenario.snapshot;
      }
      final import = await _contextAggregator.loadLabelImport(
        forceRefresh: forceRefresh,
        allowExternalData: _allowExternalStudentData(),
        taskText: taskText,
        preferenceTags: preferenceTags ?? routingLabelKeys,
      );
      _latestStudentSnapshot = import.snapshot;
      if (import.labelKeys.isNotEmpty) {
        await mergeImportedLabelSignals(
          labelKeys: import.labelKeys,
          sourceName: import.sourceName,
        );
      }
      return import.snapshot;
    } catch (error, stackTrace) {
      log(
        'Failed to refresh external student signals',
        error: error,
        stackTrace: stackTrace,
      );
      return _latestStudentSnapshot;
    } finally {
      _isRefreshingExternalSignals = false;
      notifyListeners();
    }
  }

  bool _allowExternalStudentData() {
    if (!Hive.isBoxOpen(Constants.settingsBox)) {
      return false;
    }
    final settingsBox = Boxes.getSettings();
    if (settingsBox.isEmpty) {
      return false;
    }
    final settings = settingsBox.getAt(0);
    return (settings?.allowExternalStudentData ?? false) &&
        !(settings?.preferDemoFixture ?? false);
  }

  bool _preferDemoFixture() {
    if (!Hive.isBoxOpen(Constants.settingsBox)) {
      return false;
    }
    final settingsBox = Boxes.getSettings();
    if (settingsBox.isEmpty) {
      return false;
    }
    return settingsBox.getAt(0)?.preferDemoFixture ?? false;
  }
}
