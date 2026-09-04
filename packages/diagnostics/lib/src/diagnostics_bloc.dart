import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'diagnosis.dart';
import 'diagnostics_repository.dart';

sealed class DiagnosticsEvent {
  const DiagnosticsEvent();
}

class DiagnosticsRequested extends DiagnosticsEvent {
  const DiagnosticsRequested();
}

sealed class DiagnosticsState {
  const DiagnosticsState();
}

class DiagnosticsInitial extends DiagnosticsState {
  const DiagnosticsInitial();
}

class DiagnosticsLoading extends DiagnosticsState {
  const DiagnosticsLoading();
}

class DiagnosticsLoaded extends DiagnosticsState {
  const DiagnosticsLoaded(this.diagnosis);

  final Diagnosis diagnosis;
}

class DiagnosticsFailed extends DiagnosticsState {
  const DiagnosticsFailed(this.failure);

  final AppFailure failure;
}

/// The diagnostic run is user-triggered (a "Run diagnostics" button, not
/// something that fires automatically on every dashboard load) — see
/// docs/PRODUCT_DISCOVERY.md's primary user journey: diagnostics is a
/// deliberate step the traveller takes after noticing a problem, not
/// background noise.
class DiagnosticsBloc extends Bloc<DiagnosticsEvent, DiagnosticsState> {
  DiagnosticsBloc(this._repository) : super(const DiagnosticsInitial()) {
    on<DiagnosticsRequested>(_onRequested);
  }

  final DiagnosticsRepository _repository;

  Future<void> _onRequested(
    DiagnosticsRequested event,
    Emitter<DiagnosticsState> emit,
  ) async {
    emit(const DiagnosticsLoading());
    final result = await _repository.runDiagnostics();
    result.fold(
      (diagnosis) => emit(DiagnosticsLoaded(diagnosis)),
      (failure) => emit(DiagnosticsFailed(failure)),
    );
  }
}
