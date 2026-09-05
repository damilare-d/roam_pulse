import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_harness.dart';

/// The journey's AI step (docs/PRODUCT_DISCOVERY.md §3): "AI agent can
/// provide contextual guidance". No `ANTHROPIC_API_KEY` is provisioned in
/// this environment (see ADR-008), so this test doubles as a regression
/// guard on the fallback path's honesty — the exact thing verified by
/// hand at the end of Phase 11: a fallback answer must say so, never
/// present itself as a genuine AI recommendation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the AI recommendation button shows an honestly-labelled fallback when Claude is unconfigured',
    (tester) async {
      final harness = await IntegrationHarness.build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue in demo mode'));
      await tester.pumpAndSettle();

      await tapEnsuringVisible(tester, find.text('View connection details'));
      await tester.pumpAndSettle();

      await tapEnsuringVisible(tester, find.text('Run diagnostics'));
      await tester.pumpAndSettle();

      await tapEnsuringVisible(tester, find.text('Get AI recommendation'));
      await tester.pumpAndSettle();

      expect(find.text('Fallback (AI unavailable)'), findsOneWidget);
      expect(find.text('AI recommendation'), findsNothing);
      expect(find.text('Everything looks good'), findsWidgets);
    },
  );
}
