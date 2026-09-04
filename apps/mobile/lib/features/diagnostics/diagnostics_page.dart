import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:diagnostics/diagnostics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A deliberate, user-triggered step (see DiagnosticsBloc's doc comment) —
/// this page always runs a fresh check rather than reusing any cached
/// connectivity data, since diagnosing a problem is exactly the moment a
/// stale answer would be actively unhelpful.
@RoutePage()
class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DiagnosticsBloc(context.read<DiagnosticsRepository>())
            ..add(const DiagnosticsRequested()),
      child: const _DiagnosticsView(),
    );
  }
}

class _DiagnosticsView extends StatelessWidget {
  const _DiagnosticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: BlocBuilder<DiagnosticsBloc, DiagnosticsState>(
        builder: (context, state) {
          return switch (state) {
            DiagnosticsInitial() || DiagnosticsLoading() => const LoadingView(
              message: 'Running diagnostics…',
            ),
            DiagnosticsFailed(:final failure) => ErrorView(
              message: failure.message,
              onRetry: () => context.read<DiagnosticsBloc>().add(
                const DiagnosticsRequested(),
              ),
            ),
            DiagnosticsLoaded(:final diagnosis) => ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                RoamPulseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusIndicator(
                        label: diagnosis.issue,
                        tone: _severityTone(diagnosis.severity),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Confidence: ${(diagnosis.confidence * 100).round()}%',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('Checks', style: AppTypography.label),
                      const SizedBox(height: AppSpacing.xs),
                      for (final check in diagnosis.checks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Icon(
                                check.passed
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 18,
                                color: check.passed
                                    ? AppColors.positive
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(check.label, style: AppTypography.body),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Text(diagnosis.recommendation, style: AppTypography.body),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.read<DiagnosticsBloc>().add(
                      const DiagnosticsRequested(),
                    ),
                    child: const Text('Run again'),
                  ),
                ),
              ],
            ),
          };
        },
      ),
    );
  }
}

StatusTone _severityTone(String severity) => switch (severity) {
  'high' => StatusTone.negative,
  'medium' => StatusTone.warning,
  _ => StatusTone.positive,
};
