import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String _settingsBoxName = 'settings_box';
  static const String _cacheBoxName = 'cache_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_settingsBoxName);
    await Hive.openBox(_cacheBoxName);
  }

  // Settings/Preferences Box Methods
  static Future<void> saveSetting<T>(String key, T value) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_settingsBoxName);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> deleteSetting(String key) async {
    final box = Hive.box(_settingsBoxName);
    await box.delete(key);
  }

  // General Cache Box Methods
  static Future<void> saveCache<T>(String key, T value) async {
    final box = Hive.box(_cacheBoxName);
    await box.put(key, value);
  }

  static T? getCache<T>(String key, {T? defaultValue}) {
    final box = Hive.box(_cacheBoxName);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> clearCache() async {
    final box = Hive.box(_cacheBoxName);
    await box.clear();
  }
}
