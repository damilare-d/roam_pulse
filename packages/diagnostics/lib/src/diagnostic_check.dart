class DiagnosticCheck {
  const DiagnosticCheck({required this.label, required this.passed});

  final String label;
  final bool passed;

  factory DiagnosticCheck.fromJson(Map<String, dynamic> json) {
    return DiagnosticCheck(
      label: json['label'] as String,
      passed: json['passed'] as bool,
    );
  }
}
