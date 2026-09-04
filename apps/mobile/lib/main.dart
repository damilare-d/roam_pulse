import 'dart:io' show Platform;

import 'package:connectivity/connectivity.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:network/network.dart';
import 'package:plans/plans.dart';
import 'package:storage/storage.dart';

import 'app.dart';
import 'features/auth/auth_repository.dart';

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

  runApp(
    RoamPulseApp(
      tripRepository: tripRepository,
      planRepository: planRepository,
      usageRepository: usageRepository,
      authRepository: authRepository,
      connectivityRepository: connectivityRepository,
      diagnosticsRepository: diagnosticsRepository,
    ),
  );
}

/// The Android emulator can't reach the host machine via `localhost` — it
/// needs the special `10.0.2.2` loopback alias. Every other target
/// (desktop, iOS simulator) reaches the dev backend via plain `localhost`.
/// This whole scheme is a Phase 3 dev-only convenience; Phase 4+ moves
/// backend configuration to a proper build-time/environment setup.
String _resolveBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
