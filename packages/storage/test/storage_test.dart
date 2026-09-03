import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    late KeyValueStore store;

    setUp(() => store = InMemoryKeyValueStore());

    test('returns null for a key that was never set', () async {
      expect(await store.getString('missing'), isNull);
    });

    test('round-trips a value through setString/getString', () async {
      await store.setString('trip.cache', '{"city":"Tokyo"}');
      expect(await store.getString('trip.cache'), '{"city":"Tokyo"}');
    });

    test('remove deletes only the given key', () async {
      await store.setString('a', '1');
      await store.setString('b', '2');

      await store.remove('a');

      expect(await store.getString('a'), isNull);
      expect(await store.getString('b'), '2');
    });

    test('clear removes every key', () async {
      await store.setString('a', '1');
      await store.setString('b', '2');

      await store.clear();

      expect(await store.getString('a'), isNull);
      expect(await store.getString('b'), isNull);
    });
  });
}
