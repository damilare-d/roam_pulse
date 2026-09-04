import 'package:diagnostics/diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Diagnosis.fromJson', () {
    test('parses the network-unavailable example from the product brief', () {
      final diagnosis = Diagnosis.fromJson({
        'issue': 'Network unavailable',
        'confidence': 0.9,
        'severity': 'high',
        'checks': [
          {'label': 'Plan active', 'passed': true},
          {'label': 'eSIM active', 'passed': true},
          {'label': 'Network registered', 'passed': false},
        ],
        'recommendation': 'Check your network registration.',
      });

      expect(diagnosis.issue, 'Network unavailable');
      expect(diagnosis.confidence, 0.9);
      expect(diagnosis.severity, 'high');
      expect(diagnosis.checks, hasLength(3));
      expect(diagnosis.checks.last.label, 'Network registered');
      expect(diagnosis.checks.last.passed, isFalse);
      expect(diagnosis.recommendation, 'Check your network registration.');
    });

    test('parses a healthy result with all checks passing', () {
      final diagnosis = Diagnosis.fromJson({
        'issue': 'Everything looks good',
        'confidence': 0.95,
        'severity': 'low',
        'checks': [
          {'label': 'Plan active', 'passed': true},
        ],
        'recommendation': 'No issues detected with your connection.',
      });

      expect(
        diagnosis.checks,
        everyElement(predicate<DiagnosticCheck>((c) => c.passed)),
      );
    });
  });
}
