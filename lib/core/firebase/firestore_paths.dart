/// Firestore collection paths for AeroFit.
class FirestorePaths {
  static String user(String uid) => 'users/$uid';

  static String tasks(String uid) => '${user(uid)}/tasks';
  static String dailyTasks(String uid) => '${user(uid)}/daily_tasks';
  static String meals(String uid) => '${user(uid)}/meals';
  static String mealLogs(String uid) => '${user(uid)}/meal_logs';
  static String workoutSessions(String uid) => '${user(uid)}/workout_sessions';
  static String workoutSplits(String uid) => '${user(uid)}/workout_splits';
  static String exercises(String uid) => '${user(uid)}/exercises';
  static String exerciseImages(String uid) => '${user(uid)}/exercise_images';
  static String weightEntries(String uid) => '${user(uid)}/weight_entries';
}
