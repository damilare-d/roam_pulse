import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityRepository implements ConnectivityRepository {
  _FakeConnectivityRepository({
    Result<Cached<ConnectivityStatus>>? status,
    Result<Cached<List<ConnectivityEvent>>>? events,
  }) : _status = status ?? const Err(ServerFailure()),
       _events =
           events ??
           Ok(
             Cached(
               value: const <ConnectivityEvent>[],
               syncedAt: _epoch,
               isStale: false,
             ),
           );

  final Result<Cached<ConnectivityStatus>> _status;
  final Result<Cached<List<ConnectivityEvent>>> _events;

  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async => _status;

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async => _events;
}

final _epoch = DateTime.utc(2026, 1, 1);

final _connectedStatus = ConnectivityStatus(
  state: ConnectivityState.connected,
  network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
  signalStrength: 'strong',
  latencyMs: 42,
  lastEventAt: DateTime.utc(2026, 9, 1),
);

void main() {
  group('ConnectivityBloc', () {
    test('starts in ConnectivityBlocInitial', () {
      final bloc = ConnectivityBloc(
        _FakeConnectivityRepository(
          status: Ok(
            Cached(value: _connectedStatus, syncedAt: _epoch, isStale: false),
          ),
        ),
      );
      expect(bloc.state, isA<ConnectivityBlocInitial>());
    });

    test('emits [loading, loaded] with fresh data when both succeed', () {
      final bloc = ConnectivityBloc(
        _FakeConnectivityRepository(
          status: Ok(
            Cached(value: _connectedStatus, syncedAt: _epoch, isStale: false),
          ),
          events: Ok(
            Cached(
              value: [
                ConnectivityEvent(
                  occurredAt: _epoch,
                  fromState: ConnectivityState.connecting,
                  toState: ConnectivityState.connected,
                ),
              ],
              syncedAt: _epoch,
              isStale: false,
            ),
          ),
        ),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ConnectivityBlocLoading>(),
          isA<ConnectivityBlocLoaded>()
              .having(
                (s) => s.status.state,
                'status.state',
                ConnectivityState.connected,
              )
              .having((s) => s.isStale, 'isStale', isFalse),
        ]),
      );

      bloc.add(const ConnectivityStatusRequested());
    });

    test('marks the loaded state stale when either piece of data is stale', () {
      final bloc = ConnectivityBloc(
        _FakeConnectivityRepository(
          status: Ok(
            Cached(value: _connectedStatus, syncedAt: _epoch, isStale: true),
          ),
        ),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ConnectivityBlocLoading>(),
          isA<ConnectivityBlocLoaded>().having(
            (s) => s.isStale,
            'isStale',
            isTrue,
          ),
        ]),
      );

      bloc.add(const ConnectivityStatusRequested());
    });

    test(
      'emits [loading, failed] when the status fetch fails with no cache to fall back on',
      () {
        final bloc = ConnectivityBloc(
          _FakeConnectivityRepository(
            status: const Err(NetworkUnavailableFailure()),
          ),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConnectivityBlocLoading>(),
            isA<ConnectivityBlocFailed>(),
          ]),
        );

        bloc.add(const ConnectivityStatusRequested());
      },
    );

    test(
      'emits [loading, failed] when the events fetch fails even if status succeeds',
      () {
        final bloc = ConnectivityBloc(
          _FakeConnectivityRepository(
            status: Ok(
              Cached(value: _connectedStatus, syncedAt: _epoch, isStale: false),
            ),
            events: const Err(ServerFailure()),
          ),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConnectivityBlocLoading>(),
            isA<ConnectivityBlocFailed>(),
          ]),
        );

        bloc.add(const ConnectivityStatusRequested());
      },
    );
  });
}
