import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/dashboard/profile_repository.dart';
import 'router/app_router.dart';

class RoamPulseApp extends StatelessWidget {
  RoamPulseApp({required this.profileRepository, super.key});

  final ProfileRepository profileRepository;
  final AppRouter _router = AppRouter();

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: profileRepository,
      child: MaterialApp.router(
        title: 'RoamPulse',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router.config(),
      ),
    );
  }
}
