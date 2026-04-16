import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppPrefs> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPrefs._(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clearAll() => _prefs.clear();
}
