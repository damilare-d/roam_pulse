import 'package:connectivity/connectivity.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/dashboard/dashboard_page.dart';
import 'package:roam_pulse/features/dashboard/profile_repository.dart';
import 'package:roam_pulse/features/dashboard/traveller_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._result);

  final Result<TravellerProfile> _result;

  @override
  Future<Result<TravellerProfile>> getProfile() async => _result;
}

/// Kept green (connected, no errors) by default so these dashboard-page
/// tests stay focused on the profile card's own states — the
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

Widget _wrap(ProfileRepository repository) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProfileRepository>.value(value: repository),
        RepositoryProvider<ConnectivityRepository>.value(
          value: _FakeConnectivityRepository(),
        ),
      ],
      child: const DashboardPage(),
    ),
  );
}

void main() {
  testWidgets('shows a loading state before the profile resolves', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeProfileRepository(
          const Ok(TravellerProfile(displayName: 'x', homeCountry: 'y')),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('shows the traveller profile once loaded', (tester) async {
    const profile = TravellerProfile(
      displayName: 'Alex Morgan',
      homeCountry: 'United Kingdom',
    );
    await tester.pumpWidget(_wrap(_FakeProfileRepository(const Ok(profile))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Alex Morgan'), findsOneWidget);
    expect(find.textContaining('United Kingdom'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when the profile fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_FakeProfileRepository(const Err(NetworkUnavailableFailure()))),
    );
    await tester.pumpAndSettle();

    // The profile card shows its own retry; the connectivity card (kept
    // healthy by the fake above) does not, so exactly one appears.
    expect(find.text('Try again'), findsOneWidget);
  });
}
