import 'key_value_store.dart';

/// A [KeyValueStore] that never touches disk — for tests, in this package
/// and any other package/app code that needs a fast, hermetic double for
/// local persistence.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();
}
