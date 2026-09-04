import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plans/plans.dart';

import 'features/auth/auth_repository.dart';
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
    super.key,
  }) : _router = AppRouter(AuthGuard(authRepository));

  final TripRepository tripRepository;
  final PlanRepository planRepository;
  final UsageRepository usageRepository;
  final AuthRepository authRepository;
  final ConnectivityRepository connectivityRepository;
  final DiagnosticsRepository diagnosticsRepository;
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
