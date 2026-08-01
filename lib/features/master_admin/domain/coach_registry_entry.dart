class CoachRegistryEntry {
  const CoachRegistryEntry({
    required this.uid,
    required this.gymName,
    required this.coachName,
    required this.email,
    this.createdAt,
  });

  final String uid;
  final String gymName;
  final String coachName;
  final String email;
  final DateTime? createdAt;
}
