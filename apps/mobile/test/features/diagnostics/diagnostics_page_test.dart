import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/diagnostics/diagnostics_page.dart';

class _FakeDiagnosticsRepository implements DiagnosticsRepository {
  _FakeDiagnosticsRepository(this._result);

  final Result<Diagnosis> _result;

  @override
  Future<Result<Diagnosis>> runDiagnostics() async => _result;
}

Widget _wrap(DiagnosticsRepository repository) {
  return MaterialApp(
    theme: AppTheme.light,
    home: RepositoryProvider<DiagnosticsRepository>.value(
      value: repository,
      child: const DiagnosticsPage(),
    ),
  );
}

void main() {
  testWidgets('shows a healthy diagnosis with all checks passing', (
    tester,
  ) async {
    const diagnosis = Diagnosis(
      issue: 'Everything looks good',
      confidence: 0.95,
      severity: 'low',
      checks: [
        DiagnosticCheck(label: 'Plan active', passed: true),
        DiagnosticCheck(label: 'eSIM active', passed: true),
      ],
      recommendation: 'No issues detected with your connection.',
    );

    await tester.pumpWidget(
      _wrap(_FakeDiagnosticsRepository(const Ok(diagnosis))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Everything looks good'), findsOneWidget);
    expect(find.textContaining('95%'), findsOneWidget);
    expect(
      find.text('No issues detected with your connection.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets(
    'shows a failing check with a warning icon matching the brief example',
    (tester) async {
      const diagnosis = Diagnosis(
        issue: 'Network unavailable',
        confidence: 0.9,
        severity: 'high',
        checks: [
          DiagnosticCheck(label: 'Plan active', passed: true),
          DiagnosticCheck(label: 'eSIM active', passed: true),
          DiagnosticCheck(label: 'Network registered', passed: false),
        ],
        recommendation: 'Check your network registration.',
      );

      await tester.pumpWidget(
        _wrap(_FakeDiagnosticsRepository(const Ok(diagnosis))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Network unavailable'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    },
  );

  testWidgets('shows an error view with retry when the diagnostic run fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(_FakeDiagnosticsRepository(const Err(NetworkUnavailableFailure()))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try again'), findsOneWidget);
  });
}
