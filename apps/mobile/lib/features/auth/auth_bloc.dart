import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_repository.dart';

sealed class AuthEvent {
  const AuthEvent();
}

class AuthDemoSignInRequested extends AuthEvent {
  const AuthDemoSignInRequested();
}

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  const AuthSuccess();
}

class AuthFailed extends AuthState {
  const AuthFailed(this.failure);

  final AppFailure failure;
}

/// Owns the sign-in *action* (loading/error/retry for the button tap).
/// Whether a session already exists on launch is checked directly against
/// [AuthRepository] by [SplashPage] and [AuthGuard] — a one-shot read
/// doesn't need its own bloc (see ADR-002).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<AuthDemoSignInRequested>(_onDemoSignInRequested);
  }

  final AuthRepository _repository;

  Future<void> _onDemoSignInRequested(
    AuthDemoSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.signInDemo();
    result.fold(
      (_) => emit(const AuthSuccess()),
      (failure) => emit(AuthFailed(failure)),
    );
  }
}
