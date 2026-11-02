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

  /// Spark (free) plan: pass via `--dart-define=GEMINI_API_KEY=...` at run/build.
  /// Do not commit a real key. After upgrading to Blaze, prefer Cloud Function
  /// `analyzeMeal` + Secret Manager and leave this empty in production builds.
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-flash-latest',
  );

  /// Spark-first default: call Gemini from the app.
  /// Set `--dart-define=USE_MEAL_CLOUD_FUNCTION=true` only after Blaze +
  /// `analyzeMeal` is deployed.
  static const useMealCloudFunction = bool.fromEnvironment(
    'USE_MEAL_CLOUD_FUNCTION',
    defaultValue: false,
  );
}
