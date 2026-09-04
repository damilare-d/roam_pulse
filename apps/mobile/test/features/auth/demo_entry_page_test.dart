import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/auth/auth_repository.dart';
import 'package:roam_pulse/features/auth/auth_session.dart';
import 'package:roam_pulse/features/auth/demo_entry_page.dart';

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

Widget _wrap(AuthRepository repository) {
  return MaterialApp(
    theme: AppTheme.light,
    home: RepositoryProvider<AuthRepository>.value(
      value: repository,
      child: const DemoEntryPage(),
    ),
  );
}

void main() {
  testWidgets('shows the demo entry call to action', (tester) async {
    await tester.pumpWidget(
      _wrap(_FakeAuthRepository(const Ok(AuthSession(sessionToken: 't')))),
    );

    expect(find.text('RoamPulse'), findsOneWidget);
    expect(find.text('Continue in demo mode'), findsOneWidget);
  });

  testWidgets('shows an error view with retry when sign-in fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_FakeAuthRepository(const Err(ServerFailure()))),
    );

    await tester.tap(find.text('Continue in demo mode'));
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
