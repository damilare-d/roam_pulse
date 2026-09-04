import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plans/plans.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardRequested extends DashboardEvent {
  const DashboardRequested();
}

sealed class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.trip,
    required this.plan,
    required this.usage,
  });

  final TripSummary trip;
  final PlanSummary plan;
  final UsageSummary usage;
}

class DashboardFailed extends DashboardState {
  const DashboardFailed(this.failure);

  final AppFailure failure;
}

/// Connectivity deliberately stays out of this bloc — it's its own
/// independently-cached/offline-aware bloc (ConnectivityBloc, ADR-006)
/// and the thing Chaos Mode (Phase 9) will manipulate on its own. Trip,
/// plan, and usage are read-only and relatively static by comparison, so
/// they're fetched together here.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required TripRepository tripRepository,
    required PlanRepository planRepository,
    required UsageRepository usageRepository,
  }) : _tripRepository = tripRepository,
       _planRepository = planRepository,
       _usageRepository = usageRepository,
       super(const DashboardInitial()) {
    on<DashboardRequested>(_onRequested);
  }

  final TripRepository _tripRepository;
  final PlanRepository _planRepository;
  final UsageRepository _usageRepository;

  /// Trip, plan, and usage are independent reads, fetched in parallel —
  /// all three futures start before any is awaited (§11: parallel API
  /// loading), mirroring ConnectivityBloc's status+events fetch.
  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());

    final tripFuture = _tripRepository.getCurrentTrip();
    final planFuture = _planRepository.getCurrentPlanSummary();
    final usageFuture = _usageRepository.getUsageSummary();
    final tripResult = await tripFuture;
    final planResult = await planFuture;
    final usageResult = await usageFuture;

    switch (tripResult) {
      case Err(:final failure):
        emit(DashboardFailed(failure));
        return;
      case Ok():
        break;
    }
    switch (planResult) {
      case Err(:final failure):
        emit(DashboardFailed(failure));
        return;
      case Ok():
        break;
    }
    switch (usageResult) {
      case Err(:final failure):
        emit(DashboardFailed(failure));
        return;
      case Ok():
        break;
    }

    emit(
      DashboardLoaded(
        trip: tripResult.value,
        plan: planResult.value,
        usage: usageResult.value,
      ),
    );
  }
}
