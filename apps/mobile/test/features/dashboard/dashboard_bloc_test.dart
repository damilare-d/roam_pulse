import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/dashboard/dashboard_bloc.dart';
import 'package:roam_pulse/features/dashboard/profile_repository.dart';
import 'package:roam_pulse/features/dashboard/traveller_profile.dart';

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._result);

  final Result<TravellerProfile> _result;

  @override
  Future<Result<TravellerProfile>> getProfile() async => _result;
}

void main() {
  group('DashboardBloc', () {
    const profile = TravellerProfile(
      displayName: 'Alex Morgan',
      homeCountry: 'United Kingdom',
    );

    test('starts in DashboardInitial', () {
      final bloc = DashboardBloc(_FakeProfileRepository(const Ok(profile)));
      expect(bloc.state, isA<DashboardInitial>());
    });

    test('emits [loading, loaded] when the repository succeeds', () {
      final bloc = DashboardBloc(_FakeProfileRepository(const Ok(profile)));

      expectLater(
        bloc.stream,
        emitsInOrder([isA<DashboardLoading>(), isA<DashboardLoaded>()]),
      );

      bloc.add(const DashboardRequested());
    });

    test('emits [loading, failed] when the repository fails', () {
      final bloc = DashboardBloc(
        _FakeProfileRepository(const Err(NetworkUnavailableFailure())),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([isA<DashboardLoading>(), isA<DashboardFailed>()]),
      );

      bloc.add(const DashboardRequested());
    });
  });
}
