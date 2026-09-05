import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ai_recommendation.dart';
import 'ai_recovery_repository.dart';

sealed class AiRecoveryEvent {
  const AiRecoveryEvent();
}

class AiRecommendationRequested extends AiRecoveryEvent {
  const AiRecommendationRequested();
}

sealed class AiRecoveryState {
  const AiRecoveryState();
}

class AiRecoveryInitial extends AiRecoveryState {
  const AiRecoveryInitial();
}

class AiRecoveryLoading extends AiRecoveryState {
  const AiRecoveryLoading();
}

class AiRecoveryLoaded extends AiRecoveryState {
  const AiRecoveryLoaded(this.recommendation);

  final AiRecommendation recommendation;
}

class AiRecoveryFailed extends AiRecoveryState {
  const AiRecoveryFailed(this.failure);

  final AppFailure failure;
}

/// Deliberately a second, independent bloc from DiagnosticsBloc rather
/// than a mode of it — "run the deterministic check" and "ask Claude for
/// a recommendation" are two separate user actions on the diagnostics
/// page (see docs/PRODUCT_DISCOVERY.md), each with its own request and
/// failure surface. The backend endpoint reruns the deterministic
/// diagnosis itself before asking Claude, so this bloc never needs a
/// Diagnosis passed into it.
class AiRecoveryBloc extends Bloc<AiRecoveryEvent, AiRecoveryState> {
  AiRecoveryBloc(this._repository) : super(const AiRecoveryInitial()) {
    on<AiRecommendationRequested>(_onRequested);
  }

  final AiRecoveryRepository _repository;

  Future<void> _onRequested(
    AiRecommendationRequested event,
    Emitter<AiRecoveryState> emit,
  ) async {
    emit(const AiRecoveryLoading());
    final result = await _repository.getRecommendation();
    result.fold(
      (recommendation) => emit(AiRecoveryLoaded(recommendation)),
      (failure) => emit(AiRecoveryFailed(failure)),
    );
  }
}
