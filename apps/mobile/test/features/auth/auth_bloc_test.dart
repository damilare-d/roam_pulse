import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/auth/auth_bloc.dart';
import 'package:roam_pulse/features/auth/auth_repository.dart';
import 'package:roam_pulse/features/auth/auth_session.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._signInResult);

  final Result<AuthSession> _signInResult;

  @override
  Future<Result<AuthSession>> signInDemo() async => _signInResult;

  @override
  Future<bool> hasActiveSession() async => false;

  @override
  Future<void> signOut() async {}
}

void main() {
  group('AuthBloc', () {
    test('starts in AuthInitial', () {
      final bloc = AuthBloc(
        _FakeAuthRepository(const Ok(AuthSession(sessionToken: 't'))),
      );
      expect(bloc.state, isA<AuthInitial>());
    });

    test('emits [loading, success] when demo sign-in succeeds', () {
      final bloc = AuthBloc(
        _FakeAuthRepository(const Ok(AuthSession(sessionToken: 't'))),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthSuccess>()]),
      );

      bloc.add(const AuthDemoSignInRequested());
    });

    test('emits [loading, failed] when demo sign-in fails', () {
      final bloc = AuthBloc(_FakeAuthRepository(const Err(ServerFailure())));

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthFailed>()]),
      );

      bloc.add(const AuthDemoSignInRequested());
    });
  });
}
