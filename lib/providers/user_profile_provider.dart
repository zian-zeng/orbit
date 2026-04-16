import 'package:flutter/material.dart';
import 'package:chatbotapp/hive/boxes.dart';
import 'package:chatbotapp/hive/user_model.dart';
import 'package:uuid/uuid.dart';

class UserProfileProvider extends ChangeNotifier {
  String _uid = '';
  String _name = 'You';
  String _imagePath = '';
  List<String> _preferredLabelKeys = [];

  String get uid => _uid;
  String get name => _name.trim().isEmpty ? 'You' : _name.trim();
  String get firstName => name.split(' ').first;
  String get imagePath => _imagePath;
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

  Future<void> loadUser() async {
    final userBox = Boxes.getUser();
    if (userBox.isEmpty) {
      _uid = '';
      _name = 'You';
      _imagePath = '';
      _preferredLabelKeys = [];
      notifyListeners();
      return;
    }

    final user = userBox.getAt(0);
    if (user == null) {
      return;
    }

    _uid = user.uid;
    _name = user.name;
    _imagePath = user.image;
    _preferredLabelKeys = List<String>.from(user.preferredLabels);
    notifyListeners();
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
    if (updated.length > 4) {
      updated.removeRange(4, updated.length);
    }

    await saveProfile(
      name: _name,
      imagePath: _imagePath,
      preferredLabelKeys: updated,
    );
  }
}
