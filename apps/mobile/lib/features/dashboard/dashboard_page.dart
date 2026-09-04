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

/// Each card below owns its own bloc/repository and fails independently —
/// a traveller with a working (cached) connectivity section but a failed
/// profile fetch still sees the connectivity section, not a full-page
/// error. Nesting ConnectivityCard inside DashboardBloc's loaded state
/// would defeat the point of Phase 6's offline-first caching by hiding a
/// perfectly good cached result behind an unrelated failure.
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RoamPulse')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _ProfileCard(),
          SizedBox(height: AppSpacing.md),
          ConnectivityCard(),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return switch (state) {
          DashboardInitial() || DashboardLoading() => const RoamPulseCard(
            child: LoadingView(message: 'Checking your trip…'),
          ),
          DashboardFailed(:final failure) => RoamPulseCard(
            child: ErrorView(
              message: failure.message,
              onRetry: () =>
                  context.read<DashboardBloc>().add(const DashboardRequested()),
            ),
          ),
          DashboardLoaded(:final profile) => RoamPulseCard(
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
        };
      },
    );
  }
}
