import 'package:auto_route/auto_route.dart';
import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'connectivity_card.dart'
    show connectivityEventLine, connectivityStateLabel, connectivityStateTone;
import 'format_utils.dart';

/// Takes the data ConnectivityCard already fetched as route parameters
/// rather than re-fetching — the compact card shows a `.take(3)` slice of
/// the same event list this page shows in full.
@RoutePage()
class ConnectionDetailsPage extends StatelessWidget {
  const ConnectionDetailsPage({
    required this.status,
    required this.recentEvents,
    required this.syncedAt,
    required this.isStale,
    super.key,
  });

  final ConnectivityStatus status;
  final List<ConnectivityEvent> recentEvents;
  final DateTime syncedAt;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connection details')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          RoamPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusIndicator(
                  label: connectivityStateLabel(status.state),
                  tone: connectivityStateTone(status.state),
                ),
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
                  ],
                ),
                if (status.downloadMbps != null ||
                    status.uploadMbps != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (status.downloadMbps != null)
                        Expanded(
                          child: _Metric(
                            label: 'Download',
                            value:
                                '${status.downloadMbps!.toStringAsFixed(1)} Mbps',
                          ),
                        ),
                      if (status.uploadMbps != null)
                        Expanded(
                          child: _Metric(
                            label: 'Upload',
                            value:
                                '${status.uploadMbps!.toStringAsFixed(1)} Mbps',
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  isStale
                      ? 'Last synced ${relativeTime(syncedAt)} — no connection'
                      : 'Synced ${relativeTime(syncedAt)}',
                  style: AppTypography.caption.copyWith(
                    color: isStale ? AppColors.warning : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (recentEvents.isEmpty)
            const RoamPulseCard(
              child: EmptyView(
                message: 'No connectivity activity recorded yet.',
              ),
            )
          else
            RoamPulseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connection history', style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  for (final event in recentEvents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        connectivityEventLine(event),
                        style: AppTypography.body,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
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
