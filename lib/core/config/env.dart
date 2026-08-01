/// Compile-time environment via `--dart-define`.
class Env {
  static const foodVisionApiUrl = String.fromEnvironment(
    'FOOD_VISION_API_URL',
    defaultValue: 'http://localhost:8000/api/analyze-food',
  );

  static const displayName = String.fromEnvironment(
    'DISPLAY_NAME',
    defaultValue: 'Minusha',
  );

  /// Optional compile-time gate for the master admin login route.
  /// Firestore `role: "master_admin"` is the primary authorization source.
  static const masterAdminEmail = String.fromEnvironment(
    'MASTER_ADMIN_EMAIL',
    defaultValue: '',
  );

  static const dailyCalorieGoal = int.fromEnvironment(
    'DAILY_CALORIE_GOAL',
    defaultValue: 2000,
  );

  /// Must be supplied via `--dart-define=GEMINI_API_KEY=...` at build/run
  /// time — never hardcode a real key here (it would ship inside the
  /// compiled JS/APK and get flagged by GitHub secret scanning).
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash',
  );
}
