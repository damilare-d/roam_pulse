import 'package:ai_agent/ai_agent.dart';
import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plans/plans.dart';
import 'package:provider/provider.dart';

import 'features/auth/auth_repository.dart';
import 'features/chaos/chaos_mode_controller.dart';
import 'features/native_widget/native_widget_service.dart';
import 'router/app_router.dart';
import 'router/auth_guard.dart';

class RoamPulseApp extends StatelessWidget {
  RoamPulseApp({
    required this.tripRepository,
    required this.planRepository,
    required this.usageRepository,
    required this.authRepository,
    required this.connectivityRepository,
    required this.diagnosticsRepository,
    required this.aiRecoveryRepository,
    required this.nativeWidgetService,
    this.chaosModeController,
    this.chaosCacheRepository,
    super.key,
  }) : _router = AppRouter(AuthGuard(authRepository));

  final TripRepository tripRepository;
  final PlanRepository planRepository;
  final UsageRepository usageRepository;
  final AuthRepository authRepository;
  final ConnectivityRepository connectivityRepository;
  final DiagnosticsRepository diagnosticsRepository;
  final AiRecoveryRepository aiRecoveryRepository;
  final NativeWidgetService nativeWidgetService;

  /// Non-null only in debug builds (see main.dart) — Chaos Mode's route and
  /// entry-point button read these two directly, so when they're absent
  /// there is genuinely nothing chaos-related left in the widget tree,
  /// not just a hidden button.
  final ChaosModeController? chaosModeController;
  final CachingConnectivityRepository? chaosCacheRepository;
  final AppRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TripRepository>.value(value: tripRepository),
        RepositoryProvider<PlanRepository>.value(value: planRepository),
        RepositoryProvider<UsageRepository>.value(value: usageRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ConnectivityRepository>.value(
          value: connectivityRepository,
        ),
        RepositoryProvider<DiagnosticsRepository>.value(
          value: diagnosticsRepository,
        ),
        RepositoryProvider<AiRecoveryRepository>.value(
          value: aiRecoveryRepository,
        ),
        RepositoryProvider<NativeWidgetService>.value(
          value: nativeWidgetService,
        ),
        if (chaosModeController != null)
          ChangeNotifierProvider<ChaosModeController>.value(
            value: chaosModeController!,
          ),
        if (chaosCacheRepository != null)
          RepositoryProvider<CachingConnectivityRepository>.value(
            value: chaosCacheRepository!,
          ),
      ],
      child: MaterialApp.router(
        title: 'RoamPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router.config(),
      ),
    );
  }
}
