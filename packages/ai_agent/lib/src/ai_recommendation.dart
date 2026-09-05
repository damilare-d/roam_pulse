/// `POST /api/v1/diagnostics/recommend` — the Connectivity Recovery
/// Agent's output. [source] is "ai" when Claude genuinely produced this,
/// or "fallback" when the backend couldn't reach/validate Claude and
/// wrapped the deterministic diagnosis's own recommendation instead (see
/// ADR-008) — the UI must show this distinction rather than presenting a
/// fallback as if it were a real AI answer (the same honesty ADR-006
/// already requires for stale cached data).
class AiRecommendation {
  const AiRecommendation({
    required this.summary,
    required this.steps,
    required this.confidence,
    required this.escalate,
    required this.source,
  });

  final String summary;
  final List<String> steps;
  final double confidence;
  final bool escalate;
  final String source;

  bool get isFallback => source == 'fallback';

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      summary: json['summary'] as String,
      steps: (json['steps'] as List).cast<String>(),
      confidence: (json['confidence'] as num).toDouble(),
      escalate: json['escalate'] as bool,
      source: json['source'] as String,
    );
  }
}
