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

  static const dailyCalorieGoal = int.fromEnvironment(
    'DAILY_CALORIE_GOAL',
    defaultValue: 2000,
  );
}
