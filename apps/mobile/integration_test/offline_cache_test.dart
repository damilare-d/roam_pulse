import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:roam_pulse/features/chaos/chaos_condition.dart';

import 'test_harness.dart';

/// The journey's middle act (docs/PRODUCT_DISCOVERY.md §3): "Experience
/// an outage → RoamPulse detects degraded connectivity → Application
/// switches to cached/offline state ... Network is restored →
/// Application synchronizes". Chaos Mode's `NetworkCondition.offline`
/// (Phase 9) simulates the outage deterministically and instantly,
/// rather than requiring a human to kill the backend process for every
/// test run — see docs/INTEGRATION_TESTING.md.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'an outage falls back to cached data with a stale banner, then a clean refresh clears it',
    (tester) async {
      final harness = await IntegrationHarness.build();
      await tester.pumpWidget(harness.app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue in demo mode'));
      await tester.pumpAndSettle();

      // Primes the cache with a real, fresh fetch before the outage.
      expect(find.text('Connected'), findsOneWidget);
      expect(find.textContaining('no connection'), findsNothing);

      // Staleness is purely cache *age* (Cache.read's TTL check), not
      // "did the last fetch fail" — a cache primed a moment ago by this
      // same test needs to be explicitly backdated, or the outage below
      // would fall back to cache silently without ever rendering as
      // stale. This mirrors Chaos Mode's own dev-only cache controls.
      await harness.connectivityRepository.expireCache();
      harness.chaosModeController.setNetwork(NetworkCondition.offline);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      // Cached SoftBank data shown instead of an error view — ADR-006's
      // network-first-with-cache-fallback, not a hard failure.
      // `findsWidgets` (not `findsOneWidget`) because "SoftBank" also
      // appears in the recent connectivity events section.
      expect(find.text('Connected'), findsOneWidget);
      expect(find.textContaining('SoftBank'), findsWidgets);
      expect(find.textContaining('no connection'), findsOneWidget);

      harness.chaosModeController.setNetwork(NetworkCondition.normal);
      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no connection'), findsNothing);
    },
  );
}
