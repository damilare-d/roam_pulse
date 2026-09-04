import 'package:auto_route/auto_route.dart';
import 'package:connectivity/connectivity.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'chaos_condition.dart';
import 'chaos_mode_controller.dart';

/// Developer-only failure-simulation console (§13 of PRODUCT_DISCOVERY.md).
/// Reachable only from a [kDebugMode]-gated entry point on the dashboard,
/// and only built into the widget tree at all when
/// [ChaosModeController]/[CachingConnectivityRepository] were provided —
/// see app.dart. Every dial here writes straight to the controller, so
/// [ChaosInterceptor] picks up the new condition on the very next request.
@RoutePage()
class ChaosModePage extends StatelessWidget {
  const ChaosModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChaosModeController>();
    final cache = context.read<CachingConnectivityRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chaos Mode'),
        actions: [
          TextButton(
            onPressed: controller.reset,
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          RoamPulseCard(
            child: RadioGroup<NetworkCondition>(
              groupValue: controller.network,
              onChanged: (value) => controller.setNetwork(value!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Network condition', style: AppTypography.label),
                  for (final condition in NetworkCondition.values)
                    RadioListTile<NetworkCondition>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_networkLabel(condition)),
                      value: condition,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RoamPulseCard(
            child: RadioGroup<ApiCondition>(
              groupValue: controller.api,
              onChanged: (value) => controller.setApi(value!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API condition', style: AppTypography.label),
                  for (final condition in ApiCondition.values)
                    RadioListTile<ApiCondition>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_apiLabel(condition)),
                      value: condition,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RoamPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cache', style: AppTypography.label),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Clear removes cached connectivity data outright; expire keeps it but marks it stale, the same as if too much time had passed.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: RoamPulseButton(
                        label: 'Clear cache',
                        onPressed: cache.clearCache,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: RoamPulseButton(
                        label: 'Expire cache',
                        onPressed: cache.expireCache,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _networkLabel(NetworkCondition condition) => switch (condition) {
  NetworkCondition.normal => 'Normal',
  NetworkCondition.offline => 'Offline',
  NetworkCondition.slow => 'Slow (3s delay)',
  NetworkCondition.timeout => 'Timeout',
};

String _apiLabel(ApiCondition condition) => switch (condition) {
  ApiCondition.normal => 'Normal',
  ApiCondition.serverError => '500 server error',
  ApiCondition.emptyResponse => 'Empty/malformed response',
  ApiCondition.delayed => 'Delayed (2s)',
};
