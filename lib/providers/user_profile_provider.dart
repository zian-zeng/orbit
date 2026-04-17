import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:chatbotapp/constants/constants.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/chat_history.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:chatbotapp/models/prompt_recommendation.dart';
import 'package:chatbotapp/models/support_intelligence.dart';
import 'package:chatbotapp/services/label_enrichment_service.dart';
import 'package:chatbotapp/services/support_intelligence_service.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class UserProfileProvider extends ChangeNotifier {
  static const LabelEnrichmentService _labelEnrichmentService =
      LabelEnrichmentService();
  static const SupportIntelligenceService _supportIntelligenceService =
      SupportIntelligenceService();

  String _uid = '';
  String _name = 'You';
  String _imagePath = '';
  List<String> _preferredLabelKeys = [];
  List<String> _importedLabelKeys = [];
  Map<String, List<String>> _importedSourceRankings = {};
  List<String> _importedSourceNames = [];
  List<String> _routingLabelKeys = [];
  List<String> _labelSignalSources = [];
  bool _isReady = false;
  bool _shouldShowOnboarding = false;

  String get uid => _uid;
  String get name => _name.trim().isEmpty ? 'You' : _name.trim();
  String get firstName => name.split(' ').first;
  String get imagePath => _imagePath;
  bool get isReady => _isReady;
  bool get hasCompletedOnboarding => _uid.trim().isNotEmpty;
  bool get shouldShowOnboarding => _shouldShowOnboarding;
  List<String> get preferredLabelKeys =>
      List<String>.unmodifiable(_preferredLabelKeys);
  List<String> get importedLabelKeys =>
      List<String>.unmodifiable(_importedLabelKeys);
  List<String> get routingLabelKeys => _routingLabelKeys.isNotEmpty
      ? List<String>.unmodifiable(_routingLabelKeys)
      : List<String>.unmodifiable(_preferredLabelKeys);
  List<String> get labelSignalSources =>
      List<String>.unmodifiable(_labelSignalSources);
  bool get hasImage => _imagePath.trim().isNotEmpty;
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

  void _resetProfile({required bool shouldShowOnboarding}) {
    _uid = '';
    _name = 'You';
    _imagePath = '';
    _preferredLabelKeys = [];
    _importedLabelKeys = [];
    _importedSourceRankings = {};
    _importedSourceNames = [];
    _routingLabelKeys = [];
    _labelSignalSources = [];
    _shouldShowOnboarding = shouldShowOnboarding;
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
      if (userBox.isEmpty) {
        _resetProfile(shouldShowOnboarding: !_hasLegacyActivity());
        _refreshRoutingLabels();
        return;
      }

      final user = userBox.getAt(0);
      if (user == null) {
        _resetProfile(shouldShowOnboarding: !_hasLegacyActivity());
        _refreshRoutingLabels();
        return;
      }

      _uid = user.uid;
      _name = user.name;
      _imagePath = user.image;
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
      _shouldShowOnboarding = false;
    } catch (error, stackTrace) {
      _resetProfile(shouldShowOnboarding: false);
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
    List<String>? preferredLabelKeys,
    List<String>? importedLabelKeys,
    List<String>? importedSources,
    List<String>? importedSourceRankings,
  }) async {
    final trimmedName = name.trim().isEmpty ? 'You' : name.trim();
    final userBox = Boxes.getUser();
    final user = UserModel(
      uid: _uid.isEmpty ? const Uuid().v4() : _uid,
      name: trimmedName,
      image: imagePath,
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
    _imagePath = user.image;
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
    _shouldShowOnboarding = false;
    notifyListeners();
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
}
