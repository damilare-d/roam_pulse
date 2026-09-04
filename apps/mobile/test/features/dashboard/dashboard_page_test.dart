import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plans/plans.dart';
import 'package:roam_pulse/features/dashboard/dashboard_page.dart';

class _FakeTripRepository implements TripRepository {
  _FakeTripRepository(this._result);

  final Result<TripSummary> _result;

  @override
  Future<Result<TripSummary>> getCurrentTrip() async => _result;
}

class _FakePlanRepository implements PlanRepository {
  _FakePlanRepository(this._result);

  final Result<PlanSummary> _result;

  @override
  Future<Result<PlanSummary>> getCurrentPlanSummary() async => _result;
}

class _FakeUsageRepository implements UsageRepository {
  @override
  Future<Result<UsageSummary>> getUsageSummary() async =>
      const Ok(UsageSummary(planId: 'p-1', totalBytesUsed: 0, byCategory: {}));
}

/// Kept green (connected, no errors) by default so these dashboard-page
/// tests stay focused on the trip/usage cards' own states — the
/// connectivity card's own loading/error/stale behaviour is covered by
/// connectivity_card_test.dart.
class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async => Ok(
    Cached(
      value: ConnectivityStatus(
        state: ConnectivityState.connected,
        network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
        signalStrength: 'strong',
        latencyMs: 42,
        lastEventAt: DateTime.utc(2026, 9, 1),
      ),
      syncedAt: DateTime.now(),
      isStale: false,
    ),
  );

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async => Ok(
    Cached(
      value: const <ConnectivityEvent>[],
      syncedAt: DateTime.now(),
      isStale: false,
    ),
  );
}

final _travelPlan = TravelPlan(
  id: 'p-1',
  destinationId: 'd-1',
  startsAt: DateTime.utc(2026, 9, 1),
  expiresAt: DateTime.utc(2026, 9, 7),
  dataAllowanceMb: 8000,
  status: PlanStatus.active,
);

Widget _wrap({required Result<TripSummary> trip, Result<PlanSummary>? plan}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>.value(
          value: _FakeTripRepository(trip),
        ),
        RepositoryProvider<PlanRepository>.value(
          value: _FakePlanRepository(
            plan ??
                Ok(
                  PlanSummary(
                    plan: _travelPlan,
                    dataAllowanceMb: 8000,
                    dataUsedMb: 1200,
                    dataRemainingMb: 6800,
                    daysRemaining: 3,
                  ),
                ),
          ),
        ),
        RepositoryProvider<UsageRepository>.value(
          value: _FakeUsageRepository(),
        ),
        RepositoryProvider<ConnectivityRepository>.value(
          value: _FakeConnectivityRepository(),
        ),
      ],
      child: const DashboardPage(),
    ),
  );
}

void main() {
  testWidgets('shows a loading state before the trip resolves', (tester) async {
    final trip = TripSummary(
      traveller: const TravellerProfile(
        id: 't-1',
        displayName: 'x',
        homeCountry: 'y',
      ),
      destination: const Destination(
        id: 'd-1',
        countryCode: 'JP',
        city: 'Tokyo',
        timezone: 'Asia/Tokyo',
      ),
      network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
      plan: _travelPlan,
    );

    await tester.pumpWidget(_wrap(trip: Ok(trip)));

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows the trip and usage once loaded', (tester) async {
    final trip = TripSummary(
      traveller: const TravellerProfile(
        id: 't-1',
        displayName: 'Alex Morgan',
        homeCountry: 'United Kingdom',
      ),
      destination: const Destination(
        id: 'd-1',
        countryCode: 'JP',
        city: 'Tokyo',
        timezone: 'Asia/Tokyo',
      ),
      network: const NetworkInfo(carrierName: 'SoftBank', technology: '5G'),
      plan: _travelPlan,
    );

    await tester.pumpWidget(_wrap(trip: Ok(trip)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alex Morgan'), findsOneWidget);
    expect(find.textContaining('Tokyo'), findsOneWidget);
    expect(find.textContaining('6.8 GB'), findsOneWidget);
    expect(find.textContaining('Expires in 3 days'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when the trip fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(trip: const Err(NetworkUnavailableFailure())),
    );
    await tester.pumpAndSettle();

    // The trip/usage card shows its own retry; the connectivity card
    // (kept healthy by the fake above) does not, so exactly one appears.
    expect(find.text('Try again'), findsOneWidget);
  });
}
