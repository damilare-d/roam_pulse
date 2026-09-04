import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivityRepository implements ConnectivityRepository {
  _FakeConnectivityRepository({
    Result<ConnectivityStatus>? status,
    Result<List<ConnectivityEvent>>? events,
  }) : _status = status ?? const Err(ServerFailure()),
       _events = events ?? const Ok(<ConnectivityEvent>[]);

  final Result<ConnectivityStatus> _status;
  final Result<List<ConnectivityEvent>> _events;

  @override
  Future<Result<ConnectivityStatus>> getStatus() async => _status;

  @override
  Future<Result<List<ConnectivityEvent>>> getRecentEvents({
    int limit = 20,
  }) async => _events;
}

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
        _FakeConnectivityRepository(status: Ok(_connectedStatus)),
      );
      expect(bloc.state, isA<ConnectivityBlocInitial>());
    });

    test(
      'emits [loading, loaded] with both status and events when both succeed',
      () {
        final bloc = ConnectivityBloc(
          _FakeConnectivityRepository(
            status: Ok(_connectedStatus),
            events: Ok([
              ConnectivityEvent(
                occurredAt: DateTime.utc(2026, 9, 1),
                fromState: ConnectivityState.connecting,
                toState: ConnectivityState.connected,
              ),
            ]),
          ),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<ConnectivityBlocLoading>(),
            isA<ConnectivityBlocLoaded>().having(
              (s) => s.status.state,
              'status.state',
              ConnectivityState.connected,
            ),
          ]),
        );

        bloc.add(const ConnectivityStatusRequested());
      },
    );

    test('emits [loading, failed] when the status fetch fails', () {
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
    });

    test(
      'emits [loading, failed] when the events fetch fails even if status succeeds',
      () {
        final bloc = ConnectivityBloc(
          _FakeConnectivityRepository(
            status: Ok(_connectedStatus),
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
