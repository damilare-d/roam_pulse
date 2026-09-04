import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_event.dart' as domain;
import 'connectivity_repository.dart';
import 'connectivity_status.dart';

/// Naming note: `ConnectivityEvent` (imported here as `domain`) is a
/// backend-mirrored historical record, not a Bloc input — see its doc
/// comment. To avoid that name colliding with Bloc's own "Event"/"State"
/// vocabulary, this file's Bloc input/output types are prefixed
/// `ConnectivityBloc*` instead of the bare `Connectivity*` the rest of
/// RoamPulse's blocs use (see ADR-002).
sealed class ConnectivityBlocEvent {
  const ConnectivityBlocEvent();
}

class ConnectivityStatusRequested extends ConnectivityBlocEvent {
  const ConnectivityStatusRequested();
}

sealed class ConnectivityBlocState {
  const ConnectivityBlocState();
}

class ConnectivityBlocInitial extends ConnectivityBlocState {
  const ConnectivityBlocInitial();
}

class ConnectivityBlocLoading extends ConnectivityBlocState {
  const ConnectivityBlocLoading();
}

class ConnectivityBlocLoaded extends ConnectivityBlocState {
  const ConnectivityBlocLoaded({
    required this.status,
    required this.recentEvents,
  });

  final ConnectivityStatus status;
  final List<domain.ConnectivityEvent> recentEvents;
}

class ConnectivityBlocFailed extends ConnectivityBlocState {
  const ConnectivityBlocFailed(this.failure);

  final AppFailure failure;
}

class ConnectivityBloc
    extends Bloc<ConnectivityBlocEvent, ConnectivityBlocState> {
  ConnectivityBloc(this._repository) : super(const ConnectivityBlocInitial()) {
    on<ConnectivityStatusRequested>(_onStatusRequested);
  }

  final ConnectivityRepository _repository;

  /// Status and recent events are independent reads, so they're fetched
  /// in parallel — both futures start before either is awaited (§11:
  /// parallel API loading) rather than a sequential status-then-events
  /// round trip.
  Future<void> _onStatusRequested(
    ConnectivityStatusRequested event,
    Emitter<ConnectivityBlocState> emit,
  ) async {
    emit(const ConnectivityBlocLoading());

    final statusFuture = _repository.getStatus();
    final eventsFuture = _repository.getRecentEvents(limit: 5);
    final statusResult = await statusFuture;
    final eventsResult = await eventsFuture;

    switch (statusResult) {
      case Err(:final failure):
        emit(ConnectivityBlocFailed(failure));
        return;
      case Ok():
        break;
    }
    switch (eventsResult) {
      case Err(:final failure):
        emit(ConnectivityBlocFailed(failure));
        return;
      case Ok():
        break;
    }

    emit(
      ConnectivityBlocLoaded(
        status: statusResult.value,
        recentEvents: eventsResult.value,
      ),
    );
  }
}
