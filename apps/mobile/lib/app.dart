import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/auth_repository.dart';
import 'features/dashboard/profile_repository.dart';
import 'router/app_router.dart';
import 'router/auth_guard.dart';

class RoamPulseApp extends StatelessWidget {
  RoamPulseApp({
    required this.profileRepository,
    required this.authRepository,
    super.key,
  }) : _router = AppRouter(AuthGuard(authRepository));

  final ProfileRepository profileRepository;
  final AuthRepository authRepository;
  final AppRouter _router;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
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
