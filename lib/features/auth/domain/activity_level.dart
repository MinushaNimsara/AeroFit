enum ActivityLevel {
  sedentary(
    'sedentary',
    'Sedentary (Little to no exercise)',
    1.2,
  ),
  lightlyActive('lightly_active', 'Lightly Active', 1.375),
  moderatelyActive('moderately_active', 'Moderately Active', 1.55),
  veryActive('very_active', 'Very Active', 1.725);

  const ActivityLevel(this.firestoreValue, this.label, this.multiplier);

  final String firestoreValue;
  final String label;
  final double multiplier;

  static ActivityLevel fromString(String? value) {
    return ActivityLevel.values.firstWhere(
      (level) => level.firestoreValue == value,
      orElse: () => ActivityLevel.sedentary,
    );
  }
}
