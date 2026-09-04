import 'package:auto_route/auto_route.dart';
import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../router/app_router.dart';
import 'format_utils.dart';

/// Renders live connectivity status inside the dashboard shell. Mapping
/// [ConnectivityState] to a display label and [StatusTone] lives here,
/// not in `packages/connectivity` or `packages/design_system` — the
/// state machine stays UI-agnostic, the tone palette stays
/// domain-agnostic, and this is the one place that knows both (see
/// ADR-001). [connectivityStateLabel]/[connectivityStateTone]/
/// [connectivityEventLine] are public so ConnectionDetailsPage reuses the
/// exact same mapping instead of a second copy.
///
/// The stale/offline banner below is the concrete answer to
/// docs/PRODUCT_DISCOVERY.md's "never make cached data look identical to
/// fresh data" — see ADR-006 for the caching strategy behind it.
class ConnectivityCard extends StatelessWidget {
  const ConnectivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ConnectivityBloc(context.read<ConnectivityRepository>())
            ..add(const ConnectivityStatusRequested()),
      child: const _ConnectivityView(),
    );
  }
}

class _ConnectivityView extends StatelessWidget {
  const _ConnectivityView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityBlocState>(
      builder: (context, state) {
        return switch (state) {
          ConnectivityBlocInitial() ||
          ConnectivityBlocLoading() => const RoamPulseCard(
            child: LoadingView(message: 'Checking your connection…'),
          ),
          ConnectivityBlocFailed(:final failure) => RoamPulseCard(
            child: ErrorView(
              message: failure.message,
              onRetry: () => context.read<ConnectivityBloc>().add(
                const ConnectivityStatusRequested(),
              ),
            ),
          ),
          ConnectivityBlocLoaded(
            :final status,
            :final recentEvents,
            :final syncedAt,
            :final isStale,
          ) =>
            RoamPulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatusIndicator(
                          label: connectivityStateLabel(status.state),
                          tone: connectivityStateTone(status.state),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh',
                        onPressed: () => context.read<ConnectivityBloc>().add(
                          const ConnectivityStatusRequested(),
                        ),
                      ),
                    ],
                  ),
                  if (isStale) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Showing saved data from ${relativeTime(syncedAt)} — no connection',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${status.network.carrierName} · ${status.network.technology}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Signal',
                          value: status.signalStrength,
                        ),
                      ),
                      if (status.latencyMs != null)
                        Expanded(
                          child: _Metric(
                            label: 'Latency',
                            value: '${status.latencyMs} ms',
                          ),
                        ),
                      if (status.downloadMbps != null)
                        Expanded(
                          child: _Metric(
                            label: 'Download',
                            value:
                                '${status.downloadMbps!.toStringAsFixed(0)} Mbps',
                          ),
                        ),
                    ],
                  ),
                  if (recentEvents.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    const Text('Recent activity', style: AppTypography.label),
                    const SizedBox(height: AppSpacing.xs),
                    for (final event in recentEvents.take(3))
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          connectivityEventLine(event),
                          style: AppTypography.caption,
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.router.push(
                        ConnectionDetailsRoute(
                          status: status,
                          recentEvents: recentEvents,
                          syncedAt: syncedAt,
                          isStale: isStale,
                        ),
                      ),
                      child: const Text('View connection details'),
                    ),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        Text(value, style: AppTypography.label),
      ],
    );
  }
}

String connectivityStateLabel(ConnectivityState state) => switch (state) {
  ConnectivityState.unknown => 'Unknown',
  ConnectivityState.connecting => 'Connecting…',
  ConnectivityState.connected => 'Connected',
  ConnectivityState.degraded => 'Degraded connection',
  ConnectivityState.offline => 'Offline',
  ConnectivityState.synchronizing => 'Syncing…',
  ConnectivityState.error => 'Connection error',
};

StatusTone connectivityStateTone(ConnectivityState state) => switch (state) {
  ConnectivityState.connected => StatusTone.positive,
  ConnectivityState.degraded => StatusTone.warning,
  ConnectivityState.offline || ConnectivityState.error => StatusTone.negative,
  ConnectivityState.unknown ||
  ConnectivityState.connecting ||
  ConnectivityState.synchronizing => StatusTone.neutral,
};

String connectivityEventLine(ConnectivityEvent event) {
  final reason = event.reason;
  if (reason != null && reason.isNotEmpty) {
    return reason;
  }
  return '${connectivityStateLabel(event.fromState)} → ${connectivityStateLabel(event.toState)}';
}
