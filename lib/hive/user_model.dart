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

  // constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.image,
    this.preferredLabels = const [],
  });
}
