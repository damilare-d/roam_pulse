import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_harness.dart';

/// The journey's diagnostics step (docs/PRODUCT_DISCOVERY.md §3): "User
/// opens diagnostics → Diagnostic engine determines likely issue" —
/// against the real deterministic engine (ADR-009), not a fake result.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'running diagnostics on the healthy seed scenario reports no issues',
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

      expect(find.text('Everything looks good'), findsOneWidget);
      expect(find.textContaining('Confidence:'), findsOneWidget);
      expect(find.text('Checks'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    },
  );
}
