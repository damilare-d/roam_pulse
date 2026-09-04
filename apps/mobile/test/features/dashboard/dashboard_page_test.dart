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

class _FakeConnectivityRepository implements ConnectivityRepository {
  @override
  Future<Result<ConnectivityStatus>> getStatus() async =>
      const Err(NetworkUnavailableFailure());

  @override
  Future<Result<List<ConnectivityEvent>>> getRecentEvents({
    int limit = 20,
  }) async => const Ok([]);
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

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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

  testWidgets('shows an error view with retry when the fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_FakeProfileRepository(const Err(NetworkUnavailableFailure()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
