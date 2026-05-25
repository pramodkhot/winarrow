import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static int get currentLevel => _prefs?.getInt('current_level') ?? 1;
  static bool get soundsEnabled => _prefs?.getBool('sounds_enabled') ?? true;
  static bool get vibrationsEnabled =>
      _prefs?.getBool('vibrations_enabled') ?? true;
  static bool get darkMode => _prefs?.getBool('dark_mode') ?? false;
  static bool get adsRemoved => _prefs?.getBool('ads_removed') ?? false;

  static Future<void> setCurrentLevel(int v) =>
      _prefs!.setInt('current_level', v);
  static Future<void> setSoundsEnabled(bool v) =>
      _prefs!.setBool('sounds_enabled', v);
  static Future<void> setVibrationsEnabled(bool v) =>
      _prefs!.setBool('vibrations_enabled', v);
  static Future<void> setDarkMode(bool v) => _prefs!.setBool('dark_mode', v);
  static Future<void> setAdsRemoved(bool v) =>
      _prefs!.setBool('ads_removed', v);

  static Future<void> advanceLevel() async {
    await setCurrentLevel(currentLevel + 1);
  }
}
