import 'gender.dart';

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.province,
    required this.district,
    required this.distanceKm,
    required this.photoUrl,
    required this.university,
    required this.occupation,
    this.interests = const [],
    this.isOnline = false,
    this.lastActiveMinutes,
    this.isVerified = false,
    this.bio = '',
  });

  final String id;
  final String name;
  final Gender gender;
  final int age;
  final String province;
  final String district;
  final double distanceKm;
  final String photoUrl;
  final String university;
  final String occupation;
  final List<String> interests;
  final bool isOnline;
  final int? lastActiveMinutes;
  final bool isVerified;
  final String bio;

  String? get status => bio;

  String get statusLabel {
    if (isOnline) return 'ออนไลน์';
    if (lastActiveMinutes != null) {
      return 'เมื่อ ${lastActiveMinutes!} นาทีที่แล้ว';
    }
    return 'ออฟไลน์';
  }
}
