import 'dart:io' show Platform;

import 'package:ai_agent/ai_agent.dart';
import 'package:connectivity/connectivity.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:plans/plans.dart';
import 'package:storage/storage.dart';

import 'app.dart';
import 'features/auth/auth_repository.dart';
import 'features/chaos/chaos_interceptor.dart';
import 'features/chaos/chaos_mode_controller.dart';
import 'features/native_widget/method_channel_native_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(
    config: ApiConfig(baseUrl: _resolveBaseUrl(), enableLogging: true),
  );
  final store = await SharedPreferencesStore.create();

  final tripRepository = HttpTripRepository(apiClient);
  final planRepository = HttpPlanRepository(apiClient);
  final usageRepository = HttpUsageRepository(apiClient);
  final authRepository = HttpAuthRepository(apiClient, store);
  final connectivityRepository = CachingConnectivityRepository(
    HttpConnectivityRepository(apiClient),
    store,
  );
  final diagnosticsRepository = HttpDiagnosticsRepository(apiClient);
  final aiRecoveryRepository = HttpAiRecoveryRepository(apiClient);
  final nativeWidgetService = MethodChannelNativeWidgetService();

  // Chaos Mode (Phase 9) only exists at all in debug builds — the
  // controller is never constructed, the interceptor is never attached,
  // and app.dart never provides either type, so there's nothing for a
  // release build to tree-shake around, it's genuinely absent.
  ChaosModeController? chaosModeController;
  if (kDebugMode) {
    chaosModeController = ChaosModeController();
    apiClient.addInterceptor(ChaosInterceptor(chaosModeController));
  }

  runApp(
    RoamPulseApp(
      tripRepository: tripRepository,
      planRepository: planRepository,
      usageRepository: usageRepository,
      authRepository: authRepository,
      connectivityRepository: connectivityRepository,
      diagnosticsRepository: diagnosticsRepository,
      aiRecoveryRepository: aiRecoveryRepository,
      nativeWidgetService: nativeWidgetService,
      chaosModeController: chaosModeController,
      chaosCacheRepository: kDebugMode ? connectivityRepository : null,
    ),
  );
}

/// The Android emulator can't reach the host machine via `localhost` — it
/// needs the special `10.0.2.2` loopback alias, which only works for the
/// emulator, not a physical device on the same LAN (which needs the
/// host's actual IP instead). `--dart-define=BACKEND_HOST=<ip>` overrides
/// both for a real-device run, e.g. `flutter run --dart-define=BACKEND_HOST=10.71.200.14`.
/// Every other target (desktop, iOS simulator) reaches the dev backend
/// via plain `localhost`. This whole scheme is a Phase 3 dev-only
/// convenience; Phase 4+ moves backend configuration to a proper
/// build-time/environment setup.
///
/// `BACKEND_URL` (a full scheme+host URL, not just a host) takes priority
/// over all of the above — the public web demo build points this at the
/// deployed backend, e.g.
/// `--dart-define=BACKEND_URL=https://roampulse-api.onrender.com`. `dart:io`'s
/// `Platform` throws on web, so `kIsWeb` must be checked before it's ever
/// touched — not just for the demo build, but for any local `flutter run
/// -d chrome` too.
String _resolveBaseUrl() {
  const urlOverride = String.fromEnvironment('BACKEND_URL');
  if (urlOverride.isNotEmpty) {
    return urlOverride;
  }
  const hostOverride = String.fromEnvironment('BACKEND_HOST');
  if (hostOverride.isNotEmpty) {
    return 'http://$hostOverride:8080';
  }
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
