import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:uuid/uuid.dart';

class UserProfileProvider extends ChangeNotifier {
  String _uid = '';
  String _name = 'You';
  String _imagePath = '';
  List<String> _preferredLabelKeys = [];
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
    _shouldShowOnboarding = shouldShowOnboarding;
  }

  bool _hasLegacyActivity() {
    return Boxes.getChatHistory().isNotEmpty || Boxes.getSettings().isNotEmpty;
  }

  Future<void> loadUser() async {
    try {
      final userBox = Boxes.getUser();
      if (userBox.isEmpty) {
        _resetProfile(shouldShowOnboarding: !_hasLegacyActivity());
        return;
      }

      final user = userBox.getAt(0);
      if (user == null) {
        _resetProfile(shouldShowOnboarding: !_hasLegacyActivity());
        return;
      }

      _uid = user.uid;
      _name = user.name;
      _imagePath = user.image;
      _preferredLabelKeys = List<String>.from(user.preferredLabels);
      _shouldShowOnboarding = false;
    } catch (error, stackTrace) {
      _resetProfile(shouldShowOnboarding: false);
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
  }) async {
    final trimmedName = name.trim().isEmpty ? 'You' : name.trim();
    final userBox = Boxes.getUser();
    final user = UserModel(
      uid: _uid.isEmpty ? const Uuid().v4() : _uid,
      name: trimmedName,
      image: imagePath,
      preferredLabels: preferredLabelKeys ?? _preferredLabelKeys,
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
}
