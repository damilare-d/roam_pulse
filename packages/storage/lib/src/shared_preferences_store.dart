import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

/// The real [KeyValueStore], backed by the platform's native preferences
/// storage (NSUserDefaults / SharedPreferences / local storage on web).
class SharedPreferencesStore implements KeyValueStore {
  const SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}
