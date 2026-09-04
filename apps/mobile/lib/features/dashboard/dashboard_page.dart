import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_card.dart';
import 'dashboard_bloc.dart';
import 'profile_repository.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DashboardBloc(context.read<ProfileRepository>())
            ..add(const DashboardRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RoamPulse')),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardInitial() || DashboardLoading() => const LoadingView(
              message: 'Checking your trip…',
            ),
            DashboardFailed(:final failure) => ErrorView(
              message: failure.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(const DashboardRequested()),
            ),
            DashboardLoaded(:final profile) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                RoamPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good to see you, ${profile.displayName}',
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Home base: ${profile.homeCountry}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const ConnectivityCard(),
              ],
            ),
          };
        },
      ),
    );
  }
}
