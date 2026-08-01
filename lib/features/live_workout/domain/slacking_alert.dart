class SlackingAlert {
  const SlackingAlert({
    required this.traineeUid,
    required this.traineeName,
    required this.workoutName,
    required this.scheduleName,
    this.since,
  });

  final String traineeUid;
  final String traineeName;
  final String workoutName;
  final String scheduleName;
  final DateTime? since;
}
