import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  @HiveField(3)
  final List<String> preferredLabels;

  @HiveField(4)
  final List<String> importedLabels;

  @HiveField(5)
  final List<String> importedSources;

  @HiveField(6)
  final List<String> importedSourceRankings;

  @HiveField(7)
  final String email;

  @HiveField(8)
  final bool isAuthorized;

  @HiveField(9)
  final bool hasCompletedOnboarding;

  @HiveField(10)
  final bool hasCompletedGuide;

  @HiveField(11)
  final String authorizationMethod;

  @HiveField(12)
  final String authorizedAtIso;

  // constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.image,
    this.preferredLabels = const [],
    this.importedLabels = const [],
    this.importedSources = const [],
    this.importedSourceRankings = const [],
    this.email = '',
    this.isAuthorized = false,
    this.hasCompletedOnboarding = false,
    this.hasCompletedGuide = false,
    this.authorizationMethod = '',
    this.authorizedAtIso = '',
  });
}
