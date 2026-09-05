import 'package:ai_agent/ai_agent.dart';
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

/// Only exercised by the AI-recovery-specific tests below — the other
/// tests never tap "Get AI recommendation", but it still has to be
/// provided because MultiBlocProvider constructs both blocs eagerly on
/// build.
class _FakeAiRecoveryRepository implements AiRecoveryRepository {
  _FakeAiRecoveryRepository([this._result]);

  final Result<AiRecommendation>? _result;

  @override
  Future<Result<AiRecommendation>> getRecommendation() async =>
      _result ?? (throw UnimplementedError());
}

Widget _wrap(
  DiagnosticsRepository repository, {
  AiRecoveryRepository? aiRecoveryRepository,
}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DiagnosticsRepository>.value(value: repository),
        RepositoryProvider<AiRecoveryRepository>.value(
          value: aiRecoveryRepository ?? _FakeAiRecoveryRepository(),
        ),
      ],
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

  const healthyDiagnosis = Diagnosis(
    issue: 'Everything looks good',
    confidence: 0.95,
    severity: 'low',
    checks: [DiagnosticCheck(label: 'Plan active', passed: true)],
    recommendation: 'No issues detected with your connection.',
  );

  testWidgets(
    'tapping "Get AI recommendation" shows a genuine AI recommendation',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          _FakeDiagnosticsRepository(const Ok(healthyDiagnosis)),
          aiRecoveryRepository: _FakeAiRecoveryRepository(
            const Ok(
              AiRecommendation(
                summary: 'Weak signal near your current location.',
                steps: ['Move to an open area.'],
                confidence: 0.7,
                escalate: false,
                source: 'ai',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get AI recommendation'));
      await tester.pumpAndSettle();

      expect(find.text('AI recommendation'), findsOneWidget);
      expect(
        find.text('Weak signal near your current location.'),
        findsOneWidget,
      );
      expect(find.text('Move to an open area.'), findsOneWidget);
      expect(find.text('Fallback (AI unavailable)'), findsNothing);
    },
  );

  testWidgets(
    'labels a fallback recommendation honestly instead of as a real AI answer',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          _FakeDiagnosticsRepository(const Ok(healthyDiagnosis)),
          aiRecoveryRepository: _FakeAiRecoveryRepository(
            const Ok(
              AiRecommendation(
                summary: 'Everything looks good',
                steps: ['No issues detected with your connection.'],
                confidence: 0.95,
                escalate: false,
                source: 'fallback',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get AI recommendation'));
      await tester.pumpAndSettle();

      expect(find.text('Fallback (AI unavailable)'), findsOneWidget);
      expect(find.text('AI recommendation'), findsNothing);
    },
  );

  testWidgets(
    'shows an error view with retry when the AI recommendation request fails',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          _FakeDiagnosticsRepository(const Ok(healthyDiagnosis)),
          aiRecoveryRepository: _FakeAiRecoveryRepository(
            const Err(NetworkUnavailableFailure()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Get AI recommendation'));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    },
  );
}
