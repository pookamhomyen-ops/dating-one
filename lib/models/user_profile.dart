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

  UserProfile copyWith({
    String? id,
    String? name,
    Gender? gender,
    int? age,
    String? province,
    String? district,
    List<String>? photoUrls,
    String? bio,
    List<String>? interests,
    int? profileViews,
    int? likesReceived,
    String? lineId,
    String? instagram,
    String? xHandle,
    String? facebook,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      province: province ?? this.province,
      district: district ?? this.district,
      photoUrls: photoUrls ?? this.photoUrls,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      profileViews: profileViews ?? this.profileViews,
      likesReceived: likesReceived ?? this.likesReceived,
      lineId: lineId ?? this.lineId,
      instagram: instagram ?? this.instagram,
      xHandle: xHandle ?? this.xHandle,
      facebook: facebook ?? this.facebook,
    );
  }
}
