import 'diagnostic_check.dart';

/// `POST /api/v1/diagnostics` — the deterministic engine's output, kept
/// structured rather than free-form prose so the UI never has to parse a
/// sentence to know what to show (see docs/PRODUCT_DISCOVERY.md section
/// 14 and ADR-009).
class Diagnosis {
  const Diagnosis({
    required this.issue,
    required this.confidence,
    required this.severity,
    required this.checks,
    required this.recommendation,
  });

  final String issue;
  final double confidence;
  final String severity;
  final List<DiagnosticCheck> checks;
  final String recommendation;

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'] as List;
    return Diagnosis(
      issue: json['issue'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      severity: json['severity'] as String,
      checks: rawChecks
          .cast<Map<String, dynamic>>()
          .map(DiagnosticCheck.fromJson)
          .toList(),
      recommendation: json['recommendation'] as String,
    );
  }
}
