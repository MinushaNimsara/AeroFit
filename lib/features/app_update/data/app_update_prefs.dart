import 'package:shared_preferences/shared_preferences.dart';

class AppUpdatePrefs {
  static const _skippedKey = 'app_update_skipped_version_code';

  Future<int?> skippedVersionCode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_skippedKey)) return null;
    return prefs.getInt(_skippedKey);
  }

  Future<void> setSkippedVersionCode(int versionCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_skippedKey, versionCode);
  }

  Future<void> clearSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skippedKey);
  }
}
