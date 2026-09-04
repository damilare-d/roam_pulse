import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../router/app_router.dart';
import 'auth_bloc.dart';
import 'auth_repository.dart';

@RoutePage()
class DemoEntryPage extends StatelessWidget {
  const DemoEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(context.read<AuthRepository>()),
      child: const _DemoEntryView(),
    );
  }
}

class _DemoEntryView extends StatelessWidget {
  const _DemoEntryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.router.replaceAll([const DashboardRoute()]);
          }
        },
        builder: (context, state) {
          return switch (state) {
            AuthLoading() => const LoadingView(
              message: 'Setting up your demo trip…',
            ),
            AuthFailed(:final failure) => ErrorView(
              message: failure.message,
              onRetry: () =>
                  context.read<AuthBloc>().add(const AuthDemoSignInRequested()),
            ),
            AuthInitial() || AuthSuccess() => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('RoamPulse', style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Your connectivity, before you need to ask.',
                    style: AppTypography.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  RoamPulseButton(
                    label: 'Continue in demo mode',
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthDemoSignInRequested(),
                    ),
                  ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}
