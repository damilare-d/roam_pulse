import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_repository.dart';
import 'traveller_profile.dart';

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
  const DashboardLoaded(this.profile);

  final TravellerProfile profile;
}

class DashboardFailed extends DashboardState {
  const DashboardFailed(this.failure);

  final AppFailure failure;
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardInitial()) {
    on<DashboardRequested>(_onRequested);
  }

  final ProfileRepository _repository;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    final result = await _repository.getProfile();
    result.fold(
      (profile) => emit(DashboardLoaded(profile)),
      (failure) => emit(DashboardFailed(failure)),
    );
  }
}
