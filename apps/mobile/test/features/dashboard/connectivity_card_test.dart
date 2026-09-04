import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/dashboard/connectivity_card.dart';

class _FakeConnectivityRepository implements ConnectivityRepository {
  _FakeConnectivityRepository({this.statusResult, this.eventsResult});

  final Result<Cached<ConnectivityStatus>>? statusResult;
  final Result<Cached<List<ConnectivityEvent>>>? eventsResult;

  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async =>
      statusResult ?? const Err(NetworkUnavailableFailure());

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async =>
      eventsResult ??
      Ok(
        Cached(
          value: const <ConnectivityEvent>[],
          syncedAt: DateTime.now(),
          isStale: false,
        ),
      );
}

Widget _wrap(ConnectivityRepository repository) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: RepositoryProvider<ConnectivityRepository>.value(
        value: repository,
        child: const ConnectivityCard(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a connected status with network and signal', (
    tester,
  ) async {
    final status = ConnectivityStatus(
      state: ConnectivityState.connected,
      network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
      signalStrength: 'strong',
      latencyMs: 42,
      downloadMbps: 87.0,
      uploadMbps: 21.0,
      lastEventAt: DateTime.utc(2026, 9, 1),
    );

    await tester.pumpWidget(
      _wrap(
        _FakeConnectivityRepository(
          statusResult: Ok(
            Cached(value: status, syncedAt: DateTime.now(), isStale: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('SoftBank'), findsOneWidget);
    expect(find.textContaining('42 ms'), findsOneWidget);
    expect(find.textContaining('87 Mbps'), findsOneWidget);
    expect(find.textContaining('no connection'), findsNothing);
    expect(find.text('View connection details'), findsOneWidget);
  });

  testWidgets('shows recent activity with the event reason', (tester) async {
    final status = ConnectivityStatus(
      state: ConnectivityState.degraded,
      network: const NetworkInfo(carrierName: 'Orange', technology: '4G'),
      signalStrength: 'weak',
      latencyMs: 320,
      lastEventAt: DateTime.utc(2026, 5, 5),
    );
    final events = [
      ConnectivityEvent(
        occurredAt: DateTime.utc(2026, 5, 5),
        fromState: ConnectivityState.connected,
        toState: ConnectivityState.degraded,
        reason: 'high latency and packet loss',
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        _FakeConnectivityRepository(
          statusResult: Ok(
            Cached(value: status, syncedAt: DateTime.now(), isStale: false),
          ),
          eventsResult: Ok(
            Cached(value: events, syncedAt: DateTime.now(), isStale: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Degraded connection'), findsOneWidget);
    expect(find.text('high latency and packet loss'), findsOneWidget);
  });

  testWidgets(
    'shows a stale-data banner instead of pretending cached data is fresh',
    (tester) async {
      final status = ConnectivityStatus(
        state: ConnectivityState.connected,
        network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
        signalStrength: 'strong',
        latencyMs: 42,
        lastEventAt: DateTime.utc(2026, 9, 1),
      );
      final staleSince = DateTime.now().subtract(const Duration(minutes: 12));

      await tester.pumpWidget(
        _wrap(
          _FakeConnectivityRepository(
            statusResult: Ok(
              Cached(value: status, syncedAt: staleSince, isStale: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('no connection'), findsOneWidget);
      expect(find.textContaining('12 minutes ago'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an error view with retry when the status fetch fails with no cache',
    (tester) async {
      await tester.pumpWidget(_wrap(_FakeConnectivityRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    },
  );
}
