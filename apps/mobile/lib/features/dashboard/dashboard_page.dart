import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plans/plans.dart';

import '../../router/app_router.dart';
import '../native_widget/native_widget_service.dart';
import '../native_widget/plan_widget_data.dart';
import 'connectivity_card.dart';
import 'dashboard_bloc.dart';
import 'format_utils.dart';

@RoutePage()
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        tripRepository: context.read<TripRepository>(),
        planRepository: context.read<PlanRepository>(),
        usageRepository: context.read<UsageRepository>(),
      )..add(const DashboardRequested()),
      child: const _DashboardView(),
    );
  }
}

/// Trip/plan/usage render as one unit (they come from a single combined
/// fetch in DashboardBloc), while ConnectivityCard is a fully independent
/// sibling with its own bloc — see dashboard_bloc.dart's doc comment and
/// ADR-006 for why a failed trip fetch must not hide a working cached
/// connectivity section.
class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoamPulse'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report_outlined),
              tooltip: 'Chaos Mode',
              onPressed: () => context.router.push(const ChaosModeRoute()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          BlocConsumer<DashboardBloc, DashboardState>(
            listener: (context, state) {
              if (state case DashboardLoaded(:final trip, :final plan)) {
                context.read<NativeWidgetService>().updatePlan(
                  PlanWidgetData(
                    destinationCity: trip.destination.city,
                    countryCode: trip.destination.countryCode,
                    dataRemainingMb: plan.dataRemainingMb,
                    dataAllowanceMb: plan.dataAllowanceMb,
                    daysRemaining: plan.daysRemaining,
                  ),
                );
              }
            },
            builder: (context, state) {
              return switch (state) {
                DashboardInitial() || DashboardLoading() => const RoamPulseCard(
                  child: LoadingView(message: 'Checking your trip…'),
                ),
                DashboardFailed(:final failure) => RoamPulseCard(
                  child: ErrorView(
                    message: failure.message,
                    onRetry: () => context.read<DashboardBloc>().add(
                      const DashboardRequested(),
                    ),
                  ),
                ),
                DashboardLoaded(:final trip, :final plan, :final usage) =>
                  Column(
                    children: [
                      _TripCard(trip: trip, plan: plan),
                      const SizedBox(height: AppSpacing.md),
                      _UsageCard(usage: usage),
                    ],
                  ),
              };
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const ConnectivityCard(),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.plan});

  final TripSummary trip;
  final PlanSummary plan;

  @override
  Widget build(BuildContext context) {
    return RoamPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good to see you, ${trip.traveller.displayName}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${flagEmoji(trip.destination.countryCode)} ${trip.destination.city}',
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            formatMegabytes(plan.dataRemainingMb),
            style: AppTypography.heroNumber,
          ),
          Text('remaining', style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(expiryLabel(plan.daysRemaining), style: AppTypography.caption),
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage});

  final UsageSummary usage;

  @override
  Widget build(BuildContext context) {
    final categories = usage.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RoamPulseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's usage", style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
          Text(formatBytes(usage.totalBytesUsed), style: AppTypography.title),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final entry in categories)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usageCategoryLabel(entry.key),
                      style: AppTypography.body,
                    ),
                    Text(
                      formatBytes(entry.value),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
