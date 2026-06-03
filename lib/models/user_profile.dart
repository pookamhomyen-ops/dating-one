import 'gender.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.province,
    required this.district,
    required this.photoUrls,
    this.bio = '',
    this.interests = const [],
    this.profileViews = 0,
    this.likesReceived = 0,
    this.lineId = '',
    this.instagram = '',
    this.xHandle = '',
    this.facebook = '',
  });

  final String id;
  String name;
  Gender gender;
  int age;
  String province;
  String district;
  List<String> photoUrls;
  String bio;
  List<String> interests;
  int profileViews;
  int likesReceived;
  String lineId;
  String instagram;
  String xHandle;
  String facebook;

  String get primaryPhoto =>
      photoUrls.isNotEmpty ? photoUrls.first : '';
}
