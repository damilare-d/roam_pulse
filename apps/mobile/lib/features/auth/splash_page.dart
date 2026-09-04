import 'package:auto_route/auto_route.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../router/app_router.dart';
import 'auth_repository.dart';

/// A one-shot session check, not a bloc — there's no lifecycle or retry
/// behaviour here worth the machinery (see ADR-002's "don't bloc
/// everything" note).
@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final hasSession = await context.read<AuthRepository>().hasActiveSession();
    if (!mounted) return;
    context.router.replaceAll([
      hasSession ? const DashboardRoute() : const DemoEntryRoute(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingView());
  }
}
