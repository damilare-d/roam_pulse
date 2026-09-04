import 'package:auto_route/auto_route.dart';

import '../features/auth/auth_repository.dart';
import 'app_router.dart';

/// Protects routes that require an active demo session. [SplashPage]
/// already decides where a fresh launch lands, but a direct/deep-linked
/// navigation to a guarded route (§22: "deep-link-ready design") still
/// needs to be caught here.
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authRepository);

  final AuthRepository _authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final authorized = await _authRepository.hasActiveSession();
    resolver.next(authorized);
    if (!authorized) {
      router.replaceAll([const DemoEntryRoute()]);
    }
  }
}
