import 'package:ai_agent/ai_agent.dart';
import 'package:connectivity/connectivity.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network/network.dart';
import 'package:plans/plans.dart';
import 'package:roam_pulse/app.dart';
import 'package:roam_pulse/features/auth/auth_repository.dart';
import 'package:roam_pulse/features/chaos/chaos_interceptor.dart';
import 'package:roam_pulse/features/chaos/chaos_mode_controller.dart';
import 'package:roam_pulse/features/native_widget/connectivity_widget_data.dart';
import 'package:roam_pulse/features/native_widget/native_widget_service.dart';
import 'package:roam_pulse/features/native_widget/plan_widget_data.dart';
import 'package:storage/storage.dart';

/// Records every call the app makes to [NativeWidgetService] so
/// integration tests can assert the "native widget updates" step of the
/// primary journey (docs/PRODUCT_DISCOVERY.md §3) without needing to
/// inspect an actual OS home screen — that stays a manual/live check
/// (already done for Android in Phase 10; see ADR-007).
class RecordingNativeWidgetService implements NativeWidgetService {
  final List<ConnectivityWidgetData> connectivityUpdates = [];
  final List<PlanWidgetData> planUpdates = [];

  @override
  Future<void> updateConnectivity(ConnectivityWidgetData data) async {
    connectivityUpdates.add(data);
  }

  @override
  Future<void> updatePlan(PlanWidgetData data) async {
    planUpdates.add(data);
  }
}

/// Launches the real [RoamPulseApp] against a real, running backend —
/// these are integration tests in the literal sense (see
/// docs/INTEGRATION_TESTING.md): they need `go run ./cmd/api` and
/// Postgres up before they'll pass, exactly like every "live
/// verification" step performed by hand throughout this project's
/// earlier phases.
///
/// Every test gets its own [ChaosModeController], wired through the same
/// [ChaosInterceptor] Chaos Mode itself uses (Phase 9) — this is what
/// lets scenario tests simulate an outage deterministically and
/// instantly, rather than requiring a human to kill the backend process.
class IntegrationHarness {
  IntegrationHarness._({
    required this.app,
    required this.chaosModeController,
    required this.nativeWidgetService,
    required this.authRepository,
    required this.connectivityRepository,
  });

  final Widget app;
  final ChaosModeController chaosModeController;
  final RecordingNativeWidgetService nativeWidgetService;
  final AuthRepository authRepository;

  /// Exposed so tests can call [CachingConnectivityRepository.expireCache]
  /// directly — the same dev-only control Chaos Mode's own UI exposes.
  /// Staleness is purely a function of cache *age* (`Cache.read`'s TTL
  /// check — see packages/storage/lib/src/cache.dart), not of whether the
  /// most recent fetch failed, so a cache primed moments ago by this same
  /// test run needs to be explicitly backdated before a simulated outage
  /// will actually render as "stale" rather than merely falling back
  /// silently.
  final CachingConnectivityRepository connectivityRepository;

  static Future<IntegrationHarness> build({
    String baseUrl = 'http://localhost:8080',
  }) async {
    final apiClient = ApiClient(
      config: ApiConfig(baseUrl: baseUrl, enableLogging: false),
    );
    final store = await SharedPreferencesStore.create();

    final chaosModeController = ChaosModeController();
    apiClient.addInterceptor(ChaosInterceptor(chaosModeController));

    final authRepository = HttpAuthRepository(apiClient, store);
    // Every test starts logged out, regardless of what a previous manual
    // run or test left behind — unlike widget tests, integration tests
    // run against a device's real, persistent platform storage.
    await authRepository.signOut();

    final connectivityRepository = CachingConnectivityRepository(
      HttpConnectivityRepository(apiClient),
      store,
    );
    // ...and every test starts with an empty cache, so a stale banner
    // from a previous run can't leak into a test that expects a fresh
    // fetch.
    await connectivityRepository.clearCache();

    final nativeWidgetService = RecordingNativeWidgetService();

    final app = RoamPulseApp(
      tripRepository: HttpTripRepository(apiClient),
      planRepository: HttpPlanRepository(apiClient),
      usageRepository: HttpUsageRepository(apiClient),
      authRepository: authRepository,
      connectivityRepository: connectivityRepository,
      diagnosticsRepository: HttpDiagnosticsRepository(apiClient),
      aiRecoveryRepository: HttpAiRecoveryRepository(apiClient),
      nativeWidgetService: nativeWidgetService,
      chaosModeController: chaosModeController,
      chaosCacheRepository: connectivityRepository,
    );

    return IntegrationHarness._(
      app: app,
      chaosModeController: chaosModeController,
      nativeWidgetService: nativeWidgetService,
      authRepository: authRepository,
      connectivityRepository: connectivityRepository,
    );
  }
}

/// Scrolls [finder] into view before tapping it. Some buttons on the
/// dashboard/diagnostics pages sit below the fold on a small test window
/// — a plain `tester.tap` either hit-test-warns or throws when the
/// target is off-screen.
Future<void> tapEnsuringVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}
