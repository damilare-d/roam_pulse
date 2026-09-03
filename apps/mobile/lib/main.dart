import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:network/network.dart';

import 'app.dart';
import 'features/dashboard/profile_repository.dart';

void main() {
  final apiClient = ApiClient(
    config: ApiConfig(baseUrl: _resolveBaseUrl(), enableLogging: true),
  );
  final profileRepository = HttpProfileRepository(apiClient);

  runApp(RoamPulseApp(profileRepository: profileRepository));
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
