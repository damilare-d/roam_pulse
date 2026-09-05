import 'package:ai_agent/ai_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRecommendation.fromJson', () {
    test('parses a genuine AI recommendation', () {
      final rec = AiRecommendation.fromJson({
        'summary': 'Weak signal detected near your current location.',
        'steps': ['Move to an open area.', 'Toggle Airplane Mode.'],
        'confidence': 0.7,
        'escalate': false,
        'source': 'ai',
      });

      expect(rec.summary, 'Weak signal detected near your current location.');
      expect(rec.steps, hasLength(2));
      expect(rec.confidence, 0.7);
      expect(rec.escalate, isFalse);
      expect(rec.isFallback, isFalse);
    });

    test('parses a fallback recommendation and flags it as such', () {
      final rec = AiRecommendation.fromJson({
        'summary': 'Plan not active',
        'steps': [
          "Your travel plan isn't active — check its status or renew it.",
        ],
        'confidence': 0.95,
        'escalate': true,
        'source': 'fallback',
      });

      expect(rec.isFallback, isTrue);
      expect(rec.escalate, isTrue);
    });
  });
}
