import 'package:ai_agent/ai_agent.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              DiagnosticsBloc(context.read<DiagnosticsRepository>())
                ..add(const DiagnosticsRequested()),
        ),
        // Not auto-triggered like DiagnosticsBloc above — asking Claude is
        // a deliberate second step the traveller opts into from the
        // deterministic result, not something that fires on page load.
        BlocProvider(
          create: (context) =>
              AiRecoveryBloc(context.read<AiRecoveryRepository>()),
        ),
      ],
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
                const SizedBox(height: AppSpacing.md),
                const _AiRecoverySection(),
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

/// Claude is only ever called from the backend — this section just shows
/// whatever `AiRecoveryBloc` got back from `POST
/// /api/v1/diagnostics/recommend`, including honestly labelling a
/// fallback answer as such rather than presenting it as a real AI
/// recommendation (ADR-008).
class _AiRecoverySection extends StatelessWidget {
  const _AiRecoverySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiRecoveryBloc, AiRecoveryState>(
      builder: (context, state) {
        return switch (state) {
          AiRecoveryInitial() => Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => context.read<AiRecoveryBloc>().add(
                const AiRecommendationRequested(),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Get AI recommendation'),
            ),
          ),
          AiRecoveryLoading() => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: LoadingView(message: 'Asking Claude…'),
          ),
          AiRecoveryFailed(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<AiRecoveryBloc>().add(
              const AiRecommendationRequested(),
            ),
          ),
          AiRecoveryLoaded(:final recommendation) => RoamPulseCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      recommendation.isFallback
                          ? 'Fallback (AI unavailable)'
                          : 'AI recommendation',
                      style: AppTypography.label,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(recommendation.summary, style: AppTypography.body),
                const SizedBox(height: AppSpacing.md),
                for (final step in recommendation.steps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(step, style: AppTypography.body)),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Confidence: ${(recommendation.confidence * 100).round()}%'
                  '${recommendation.escalate ? ' · may need carrier support' : ''}',
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
