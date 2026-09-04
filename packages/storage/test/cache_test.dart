import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _Widget {
  const _Widget(this.name);
  final String name;
}

Map<String, dynamic> _toJson(_Widget w) => {'name': w.name};
_Widget _fromJson(Map<String, dynamic> json) => _Widget(json['name'] as String);

void main() {
  group('Cache', () {
    test('read returns null when nothing has been written', () async {
      final cache = Cache<_Widget>(
        store: InMemoryKeyValueStore(),
        key: 'widget',
        ttl: const Duration(minutes: 5),
        fromJson: _fromJson,
        toJson: _toJson,
      );

      expect(await cache.read(), isNull);
    });

    test('a value read immediately after writing is not stale', () async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final cache = Cache<_Widget>(
        store: InMemoryKeyValueStore(),
        key: 'widget',
        ttl: const Duration(minutes: 5),
        fromJson: _fromJson,
        toJson: _toJson,
        clock: () => now,
      );

      await cache.write(const _Widget('Tokyo'));
      final cached = await cache.read();

      expect(cached, isNotNull);
      expect(cached!.value.name, 'Tokyo');
      expect(cached.isStale, isFalse);
      expect(cached.syncedAt, now);
    });

    test(
      'a value read after the TTL elapses is stale, but still returned',
      () async {
        var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
        final cache = Cache<_Widget>(
          store: InMemoryKeyValueStore(),
          key: 'widget',
          ttl: const Duration(minutes: 5),
          fromJson: _fromJson,
          toJson: _toJson,
          clock: () => now,
        );

        await cache.write(const _Widget('Tokyo'));
        now = now.add(const Duration(minutes: 6));
        final cached = await cache.read();

        expect(cached, isNotNull);
        expect(cached!.value.name, 'Tokyo');
        expect(cached.isStale, isTrue);
      },
    );

    test('a value read exactly at the TTL boundary is not yet stale', () async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final cache = Cache<_Widget>(
        store: InMemoryKeyValueStore(),
        key: 'widget',
        ttl: const Duration(minutes: 5),
        fromJson: _fromJson,
        toJson: _toJson,
        clock: () => now,
      );

      await cache.write(const _Widget('Tokyo'));
      now = now.add(const Duration(minutes: 5));
      final cached = await cache.read();

      expect(cached!.isStale, isFalse);
    });

    test('write overwrites the previous value and timestamp', () async {
      var now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final cache = Cache<_Widget>(
        store: InMemoryKeyValueStore(),
        key: 'widget',
        ttl: const Duration(minutes: 5),
        fromJson: _fromJson,
        toJson: _toJson,
        clock: () => now,
      );

      await cache.write(const _Widget('Tokyo'));
      now = now.add(const Duration(minutes: 1));
      await cache.write(const _Widget('Paris'));

      final cached = await cache.read();
      expect(cached!.value.name, 'Paris');
      expect(cached.syncedAt, now);
    });

    test('clear removes the cached value', () async {
      final cache = Cache<_Widget>(
        store: InMemoryKeyValueStore(),
        key: 'widget',
        ttl: const Duration(minutes: 5),
        fromJson: _fromJson,
        toJson: _toJson,
      );

      await cache.write(const _Widget('Tokyo'));
      await cache.clear();

      expect(await cache.read(), isNull);
    });
  });
}
