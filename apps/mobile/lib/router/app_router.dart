import 'package:auto_route/auto_route.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/widgets.dart' show Key;

import '../features/auth/demo_entry_page.dart';
import '../features/auth/splash_page.dart';
import '../features/dashboard/connection_details_page.dart';
import '../features/dashboard/dashboard_page.dart';
import 'auth_guard.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(AuthGuard authGuard) : _authGuard = authGuard;

  final AuthGuard _authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: DemoEntryRoute.page),
    AutoRoute(page: DashboardRoute.page, guards: [_authGuard]),
    AutoRoute(page: ConnectionDetailsRoute.page, guards: [_authGuard]),
  ];
}
