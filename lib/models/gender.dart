enum Gender {
  female,
  male,
  other;

  String get labelTh {
    switch (this) {
      case Gender.female:
        return 'หญิง';
      case Gender.male:
        return 'ชาย';
      case Gender.other:
        return 'อื่นๆ';
    }
  }
}
