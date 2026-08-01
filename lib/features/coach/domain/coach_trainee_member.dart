class CoachTraineeMember {
  const CoachTraineeMember({
    required this.uid,
    required this.displayLabel,
    required this.caloriesConsumed,
    required this.calorieGoal,
    required this.isWorkingOut,
    this.liveStatusLabel,
  });

  final String uid;
  final String displayLabel;
  final int caloriesConsumed;
  final int calorieGoal;
  final bool isWorkingOut;
  final String? liveStatusLabel;

  String get resolvedName => displayLabel;
  String get rosterLabel => displayLabel;

  String get avatarInitial {
    final name = displayLabel.trim();
    if (name.isEmpty) return 'M';
    return name[0].toUpperCase();
  }

  double get calorieProgress =>
      calorieGoal > 0 ? (caloriesConsumed / calorieGoal).clamp(0.0, 1.5) : 0;
}
