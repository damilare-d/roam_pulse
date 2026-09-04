import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/dashboard/connection_details_page.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

void main() {
  testWidgets('shows the full status including throughput and history', (
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
    final events = [
      ConnectivityEvent(
        occurredAt: DateTime.utc(2026, 9, 1),
        fromState: ConnectivityState.connecting,
        toState: ConnectivityState.connected,
        reason: 'initial connection to SoftBank',
      ),
    ];

    await tester.pumpWidget(
      _wrap(
        ConnectionDetailsPage(
          status: status,
          recentEvents: events,
          syncedAt: DateTime.now(),
          isStale: false,
        ),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('87.0 Mbps'), findsOneWidget);
    expect(find.textContaining('21.0 Mbps'), findsOneWidget);
    expect(find.text('initial connection to SoftBank'), findsOneWidget);
    expect(find.textContaining('no connection'), findsNothing);
  });

  testWidgets('shows an empty state when there is no connection history', (
    tester,
  ) async {
    final status = ConnectivityStatus(
      state: ConnectivityState.connected,
      network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
      signalStrength: 'strong',
      lastEventAt: DateTime.utc(2026, 9, 1),
    );

    await tester.pumpWidget(
      _wrap(
        ConnectionDetailsPage(
          status: status,
          recentEvents: const [],
          syncedAt: DateTime.now(),
          isStale: false,
        ),
      ),
    );

    expect(find.text('No connectivity activity recorded yet.'), findsOneWidget);
  });

  testWidgets('shows a stale indicator when isStale is true', (tester) async {
    final status = ConnectivityStatus(
      state: ConnectivityState.connected,
      network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
      signalStrength: 'strong',
      lastEventAt: DateTime.utc(2026, 9, 1),
    );
    final staleSince = DateTime.now().subtract(const Duration(minutes: 5));

    await tester.pumpWidget(
      _wrap(
        ConnectionDetailsPage(
          status: status,
          recentEvents: const [],
          syncedAt: staleSince,
          isStale: true,
        ),
      ),
    );

    expect(find.textContaining('no connection'), findsOneWidget);
  });
}
