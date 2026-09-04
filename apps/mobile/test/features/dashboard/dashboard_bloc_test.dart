import 'package:connectivity/connectivity.dart' show NetworkInfo;
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plans/plans.dart';
import 'package:roam_pulse/features/dashboard/dashboard_bloc.dart';

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
  _FakeUsageRepository(this._result);

  final Result<UsageSummary> _result;

  @override
  Future<Result<UsageSummary>> getUsageSummary() async => _result;
}

final _travelPlan = TravelPlan(
  id: 'p-1',
  destinationId: 'd-1',
  startsAt: DateTime.utc(2026, 9, 1),
  expiresAt: DateTime.utc(2026, 9, 7),
  dataAllowanceMb: 8000,
  status: PlanStatus.active,
);

final _trip = TripSummary(
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

final _planSummary = PlanSummary(
  plan: _travelPlan,
  dataAllowanceMb: 8000,
  dataUsedMb: 1200,
  dataRemainingMb: 6800,
  daysRemaining: 3,
);

const _usageSummary = UsageSummary(
  planId: 'p-1',
  totalBytesUsed: 0,
  byCategory: {},
);

DashboardBloc _bloc({
  Result<TripSummary>? trip,
  Result<PlanSummary>? plan,
  Result<UsageSummary>? usage,
}) {
  return DashboardBloc(
    tripRepository: _FakeTripRepository(trip ?? Ok(_trip)),
    planRepository: _FakePlanRepository(plan ?? Ok(_planSummary)),
    usageRepository: _FakeUsageRepository(usage ?? const Ok(_usageSummary)),
  );
}

void main() {
  group('DashboardBloc', () {
    test('starts in DashboardInitial', () {
      expect(_bloc().state, isA<DashboardInitial>());
    });

    test('emits [loading, loaded] when trip, plan, and usage all succeed', () {
      final bloc = _bloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>()
              .having(
                (s) => s.trip.destination.city,
                'trip.destination.city',
                'Tokyo',
              )
              .having(
                (s) => s.plan.dataRemainingMb,
                'plan.dataRemainingMb',
                6800,
              ),
        ]),
      );

      bloc.add(const DashboardRequested());
    });

    test('emits [loading, failed] when the trip fetch fails', () {
      final bloc = _bloc(trip: const Err(NetworkUnavailableFailure()));

      expectLater(
        bloc.stream,
        emitsInOrder([isA<DashboardLoading>(), isA<DashboardFailed>()]),
      );

      bloc.add(const DashboardRequested());
    });

    test(
      'emits [loading, failed] when the plan fetch fails even if trip and usage succeed',
      () {
        final bloc = _bloc(plan: const Err(ServerFailure()));

        expectLater(
          bloc.stream,
          emitsInOrder([isA<DashboardLoading>(), isA<DashboardFailed>()]),
        );

        bloc.add(const DashboardRequested());
      },
    );

    test(
      'emits [loading, failed] when the usage fetch fails even if trip and plan succeed',
      () {
        final bloc = _bloc(usage: const Err(ServerFailure()));

        expectLater(
          bloc.stream,
          emitsInOrder([isA<DashboardLoading>(), isA<DashboardFailed>()]),
        );

        bloc.add(const DashboardRequested());
      },
    );
  });
}
