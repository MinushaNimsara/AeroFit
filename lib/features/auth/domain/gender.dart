enum Gender {
  male('male', 'Male'),
  female('female', 'Female');

  const Gender(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static Gender fromString(String? value) {
    return Gender.values.firstWhere(
      (gender) => gender.firestoreValue == value,
      orElse: () => Gender.male,
    );
  }
}
