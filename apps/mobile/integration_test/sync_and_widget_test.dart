import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_harness.dart';

/// The journey's closing steps (docs/PRODUCT_DISCOVERY.md §3): "Network is
/// restored → Application synchronizes → Native widget updates" is a
/// repeatable cycle, not a one-time push on first load — every
/// successful sync should push a fresh update, which is what actually
/// keeps a home-screen widget from going stale between app opens.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'every successful connectivity sync pushes a fresh native widget update',
    (tester) async {
      final harness = await IntegrationHarness.build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue in demo mode'));
      await tester.pumpAndSettle();

      expect(harness.nativeWidgetService.connectivityUpdates, isNotEmpty);
      final firstUpdate = harness.nativeWidgetService.connectivityUpdates.last;

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(
        harness.nativeWidgetService.connectivityUpdates.length,
        greaterThan(1),
        reason: 'a second successful sync should push a second widget update',
      );
      final secondUpdate = harness.nativeWidgetService.connectivityUpdates.last;
      expect(
        secondUpdate.lastSyncedAt.isAfter(firstUpdate.lastSyncedAt) ||
            secondUpdate.lastSyncedAt.isAtSameMomentAs(
              firstUpdate.lastSyncedAt,
            ),
        isTrue,
        reason:
            'a fresh sync should never push an older timestamp than the last one',
      );
    },
  );
}
