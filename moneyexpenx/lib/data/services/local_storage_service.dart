import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cache user login status/uID
  static String? getCachedUserId() {
    return _prefs?.getString('cached_uid');
  }

  static Future<void> cacheUserId(String uid) async {
    await _prefs?.setString('cached_uid', uid);
  }

  static Future<void> clearCachedUserId() async {
    await _prefs?.remove('cached_uid');
  }

  // Cache user details
  static String? getCachedUsername() {
    return _prefs?.getString('cached_username');
  }

  static Future<void> cacheUsername(String name) async {
    await _prefs?.setString('cached_username', name);
  }

  // UI preferences
  static bool isDarkMode() {
    return _prefs?.getBool('dark_mode') ?? true;
  }

  static Future<void> setDarkMode(bool dark) async {
    await _prefs?.setBool('dark_mode', dark);
  }
}
