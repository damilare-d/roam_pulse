import 'dart:convert';

import 'package:core/core.dart';

import 'key_value_store.dart';

/// A single TTL-aware cache slot on top of [KeyValueStore] — one JSON
/// value per [key], stamped with when it was written so staleness can be
/// computed on read. This is the "local cache, cache timestamps, stale
/// data handling" trio from docs/PRODUCT_DISCOVERY.md section 9;
/// repositories compose one `Cache<T>` per cached resource (see
/// `CachingConnectivityRepository`).
class Cache<T> {
  Cache({
    required this.store,
    required this.key,
    required this.ttl,
    required this.fromJson,
    required this.toJson,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final KeyValueStore store;
  final String key;
  final Duration ttl;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T value) toJson;
  final DateTime Function() _clock;

  Future<Cached<T>?> read() async {
    final raw = await store.getString(key);
    if (raw == null) {
      return null;
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final syncedAt = DateTime.parse(decoded['syncedAt'] as String);
    final value = fromJson(decoded['value'] as Map<String, dynamic>);

    return Cached(
      value: value,
      syncedAt: syncedAt,
      isStale: _clock().difference(syncedAt) > ttl,
    );
  }

  Future<void> write(T value) async {
    final payload = jsonEncode({
      'syncedAt': _clock().toIso8601String(),
      'value': toJson(value),
    });
    await store.setString(key, payload);
  }

  Future<void> clear() => store.remove(key);

  /// Rewrites the currently-cached value (if any) with a timestamp far in
  /// the past, so the next [read] reports `isStale: true` without waiting
  /// out the real TTL. Exists for Chaos Mode (Phase 9) to demonstrate the
  /// offline/stale-data UI on demand — not used by any production code
  /// path.
  Future<void> expire() async {
    final cached = await read();
    if (cached == null) {
      return;
    }
    final payload = jsonEncode({
      'syncedAt': DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      'value': toJson(cached.value),
    });
    await store.setString(key, payload);
  }
}
