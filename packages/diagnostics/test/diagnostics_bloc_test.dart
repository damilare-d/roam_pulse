import 'package:core/core.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDiagnosticsRepository implements DiagnosticsRepository {
  _FakeDiagnosticsRepository(this._result);

  final Result<Diagnosis> _result;

  @override
  Future<Result<Diagnosis>> runDiagnostics() async => _result;
}

const _healthy = Diagnosis(
  issue: 'Everything looks good',
  confidence: 0.95,
  severity: 'low',
  checks: [DiagnosticCheck(label: 'Plan active', passed: true)],
  recommendation: 'No issues detected with your connection.',
);

void main() {
  group('DiagnosticsBloc', () {
    test('starts in DiagnosticsInitial', () {
      final bloc = DiagnosticsBloc(
        _FakeDiagnosticsRepository(const Ok(_healthy)),
      );
      expect(bloc.state, isA<DiagnosticsInitial>());
    });

    test('emits [loading, loaded] when the diagnostic run succeeds', () {
      final bloc = DiagnosticsBloc(
        _FakeDiagnosticsRepository(const Ok(_healthy)),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DiagnosticsLoading>(),
          isA<DiagnosticsLoaded>().having(
            (s) => s.diagnosis.issue,
            'diagnosis.issue',
            'Everything looks good',
          ),
        ]),
      );

      bloc.add(const DiagnosticsRequested());
    });

    test('emits [loading, failed] when the diagnostic run fails', () {
      final bloc = DiagnosticsBloc(
        _FakeDiagnosticsRepository(const Err(NetworkUnavailableFailure())),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([isA<DiagnosticsLoading>(), isA<DiagnosticsFailed>()]),
      );

      bloc.add(const DiagnosticsRequested());
    });
  });
}
