import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _FakeRemote implements ConnectivityRepository {
  _FakeRemote({this.statusResult, this.eventsResult});

  Result<Cached<ConnectivityStatus>>? statusResult;
  Result<Cached<List<ConnectivityEvent>>>? eventsResult;

  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async =>
      statusResult ?? const Err(NetworkUnavailableFailure());

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async => eventsResult ?? const Err(NetworkUnavailableFailure());
}

ConnectivityStatus _status({
  ConnectivityState state = ConnectivityState.connected,
}) => ConnectivityStatus(
  state: state,
  network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
  signalStrength: 'strong',
  latencyMs: 42,
  lastEventAt: DateTime.utc(2026, 9, 1),
);

void main() {
  group('CachingConnectivityRepository.getStatus', () {
    test(
      'a successful remote fetch is returned fresh and written to cache',
      () async {
        final remote = _FakeRemote(
          statusResult: Ok(
            Cached(
              value: _status(),
              syncedAt: DateTime.utc(2026, 9, 1),
              isStale: false,
            ),
          ),
        );
        final store = InMemoryKeyValueStore();
        final repo = CachingConnectivityRepository(remote, store);

        final result = await repo.getStatus();

        expect(result, isA<Ok<Cached<ConnectivityStatus>>>());
        final cached = (result as Ok<Cached<ConnectivityStatus>>).value;
        expect(cached.isStale, isFalse);
        expect(cached.value.state, ConnectivityState.connected);

        // And it's now in the cache for a future offline read.
        expect(await store.getString('connectivity.status'), isNotNull);
      },
    );

    test('falls back to a cached value when the remote fails', () async {
      final store = InMemoryKeyValueStore();
      // Prime the cache via a successful first fetch.
      final onlineRemote = _FakeRemote(
        statusResult: Ok(
          Cached(
            value: _status(),
            syncedAt: DateTime.utc(2026, 9, 1),
            isStale: false,
          ),
        ),
      );
      await CachingConnectivityRepository(onlineRemote, store).getStatus();

      // Now the remote is unreachable.
      final offlineRemote = _FakeRemote(
        statusResult: const Err(NetworkUnavailableFailure()),
      );
      final repo = CachingConnectivityRepository(offlineRemote, store);

      final result = await repo.getStatus();

      expect(result, isA<Ok<Cached<ConnectivityStatus>>>());
      final cached = (result as Ok<Cached<ConnectivityStatus>>).value;
      expect(cached.value.state, ConnectivityState.connected);
    });

    test(
      'propagates the original failure when the remote fails and nothing is cached',
      () async {
        final remote = _FakeRemote(
          statusResult: const Err(NetworkUnavailableFailure()),
        );
        final repo = CachingConnectivityRepository(
          remote,
          InMemoryKeyValueStore(),
        );

        final result = await repo.getStatus();

        expect(result, isA<Err<Cached<ConnectivityStatus>>>());
        expect(
          (result as Err<Cached<ConnectivityStatus>>).failure,
          isA<NetworkUnavailableFailure>(),
        );
      },
    );

    test(
      'a fresh remote fetch after an offline period overwrites the stale cache',
      () async {
        final store = InMemoryKeyValueStore();
        final firstRemote = _FakeRemote(
          statusResult: Ok(
            Cached(
              value: _status(),
              syncedAt: DateTime.utc(2026, 9, 1),
              isStale: false,
            ),
          ),
        );
        await CachingConnectivityRepository(firstRemote, store).getStatus();

        final degraded = _status(state: ConnectivityState.degraded);
        final secondRemote = _FakeRemote(
          statusResult: Ok(
            Cached(
              value: degraded,
              syncedAt: DateTime.utc(2026, 9, 2),
              isStale: false,
            ),
          ),
        );
        final result = await CachingConnectivityRepository(
          secondRemote,
          store,
        ).getStatus();

        final cached = (result as Ok<Cached<ConnectivityStatus>>).value;
        expect(cached.value.state, ConnectivityState.degraded);
      },
    );
  });

  group('CachingConnectivityRepository.getRecentEvents', () {
    test('falls back to cached events when the remote fails', () async {
      final store = InMemoryKeyValueStore();
      final events = [
        ConnectivityEvent(
          occurredAt: DateTime.utc(2026, 9, 1),
          fromState: ConnectivityState.connecting,
          toState: ConnectivityState.connected,
          reason: 'initial connection',
        ),
      ];
      final onlineRemote = _FakeRemote(
        eventsResult: Ok(
          Cached(
            value: events,
            syncedAt: DateTime.utc(2026, 9, 1),
            isStale: false,
          ),
        ),
      );
      await CachingConnectivityRepository(
        onlineRemote,
        store,
      ).getRecentEvents();

      final offlineRemote = _FakeRemote(
        eventsResult: const Err(NetworkUnavailableFailure()),
      );
      final result = await CachingConnectivityRepository(
        offlineRemote,
        store,
      ).getRecentEvents();

      final cached = (result as Ok<Cached<List<ConnectivityEvent>>>).value;
      expect(cached.value, hasLength(1));
      expect(cached.value.first.reason, 'initial connection');
    });
  });

  group('CachingConnectivityRepository dev-only cache controls', () {
    test(
      'clearCache removes both cached slots, so a later offline read has nothing to fall back on',
      () async {
        final store = InMemoryKeyValueStore();
        final onlineRemote = _FakeRemote(
          statusResult: Ok(
            Cached(
              value: _status(),
              syncedAt: DateTime.utc(2026, 9, 1),
              isStale: false,
            ),
          ),
        );
        final repo = CachingConnectivityRepository(onlineRemote, store);
        await repo.getStatus();

        await repo.clearCache();

        final offlineRepo = CachingConnectivityRepository(
          _FakeRemote(statusResult: const Err(NetworkUnavailableFailure())),
          store,
        );
        final result = await offlineRepo.getStatus();

        expect(result, isA<Err<Cached<ConnectivityStatus>>>());
      },
    );

    test(
      'expireCache marks the cached status stale without deleting it',
      () async {
        final store = InMemoryKeyValueStore();
        final onlineRemote = _FakeRemote(
          statusResult: Ok(
            Cached(
              value: _status(),
              syncedAt: DateTime.utc(2026, 9, 1),
              isStale: false,
            ),
          ),
        );
        final repo = CachingConnectivityRepository(onlineRemote, store);
        await repo.getStatus();

        await repo.expireCache();

        final offlineRepo = CachingConnectivityRepository(
          _FakeRemote(statusResult: const Err(NetworkUnavailableFailure())),
          store,
        );
        final result = await offlineRepo.getStatus();

        final cached = (result as Ok<Cached<ConnectivityStatus>>).value;
        expect(cached.isStale, isTrue);
        expect(cached.value.state, ConnectivityState.connected);
      },
    );
  });
}
