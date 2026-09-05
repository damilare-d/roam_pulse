import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_harness.dart';

/// The primary user journey's first half (docs/PRODUCT_DISCOVERY.md §3):
/// open RoamPulse, enter demo mode, see the current trip, connectivity,
/// data remaining, plan expiry, network, and usage — all from the real
/// backend, no mocks.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo sign-in reaches a fully loaded dashboard', (tester) async {
    final harness = await IntegrationHarness.build();
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();

    expect(find.text('Continue in demo mode'), findsOneWidget);
    await tester.tap(find.text('Continue in demo mode'));
    await tester.pumpAndSettle();

    // Trip + plan (seed data: Alex Morgan, Tokyo, SoftBank).
    expect(find.textContaining('Tokyo'), findsOneWidget);
    expect(find.text('remaining'), findsOneWidget);

    // Usage.
    expect(find.text("Today's usage"), findsOneWidget);

    // Connectivity — healthy seed scenario. `findsWidgets` (not
    // `findsOneWidget`) because "SoftBank" also appears in the recent
    // connectivity events section, not just the network line.
    expect(find.text('Connected'), findsOneWidget);
    expect(find.textContaining('SoftBank'), findsWidgets);

    // The dashboard's successful load pushed both native widget updates —
    // the "Native widget updates" step of the journey, verified without
    // needing to inspect an actual home screen (see ADR-007).
    expect(harness.nativeWidgetService.planUpdates, isNotEmpty);
    expect(harness.nativeWidgetService.connectivityUpdates, isNotEmpty);
    expect(
      harness.nativeWidgetService.planUpdates.last.destinationCity,
      'Tokyo',
    );
    expect(
      harness.nativeWidgetService.connectivityUpdates.last.carrierName,
      'SoftBank',
    );
  });
}
