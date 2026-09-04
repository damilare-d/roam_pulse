import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/dashboard/connectivity_card.dart';

class _FakeConnectivityRepository implements ConnectivityRepository {
  _FakeConnectivityRepository({this.statusResult, this.eventsResult});

  final Result<ConnectivityStatus>? statusResult;
  final Result<List<ConnectivityEvent>>? eventsResult;

  @override
  Future<Result<ConnectivityStatus>> getStatus() async =>
      statusResult ?? const Err(NetworkUnavailableFailure());

  @override
  Future<Result<List<ConnectivityEvent>>> getRecentEvents({
    int limit = 20,
  }) async => eventsResult ?? const Ok([]);
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
      lastEventAt: DateTime.utc(2026, 9, 1),
    );

    await tester.pumpWidget(
      _wrap(_FakeConnectivityRepository(statusResult: Ok(status))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('SoftBank'), findsOneWidget);
    expect(find.textContaining('42 ms'), findsOneWidget);
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
          statusResult: Ok(status),
          eventsResult: Ok(events),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Degraded connection'), findsOneWidget);
    expect(find.text('high latency and packet loss'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when the status fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeConnectivityRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
