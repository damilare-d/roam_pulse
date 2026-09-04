// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [ConnectionDetailsPage]
class ConnectionDetailsRoute extends PageRouteInfo<ConnectionDetailsRouteArgs> {
  ConnectionDetailsRoute({
    required ConnectivityStatus status,
    required List<ConnectivityEvent> recentEvents,
    required DateTime syncedAt,
    required bool isStale,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ConnectionDetailsRoute.name,
         args: ConnectionDetailsRouteArgs(
           status: status,
           recentEvents: recentEvents,
           syncedAt: syncedAt,
           isStale: isStale,
           key: key,
         ),
         initialChildren: children,
       );

  static const String name = 'ConnectionDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConnectionDetailsRouteArgs>();
      return ConnectionDetailsPage(
        status: args.status,
        recentEvents: args.recentEvents,
        syncedAt: args.syncedAt,
        isStale: args.isStale,
        key: args.key,
      );
    },
  );
}

class ConnectionDetailsRouteArgs {
  const ConnectionDetailsRouteArgs({
    required this.status,
    required this.recentEvents,
    required this.syncedAt,
    required this.isStale,
    this.key,
  });

  final ConnectivityStatus status;

  final List<ConnectivityEvent> recentEvents;

  final DateTime syncedAt;

  final bool isStale;

  final Key? key;

  @override
  String toString() {
    return 'ConnectionDetailsRouteArgs{status: $status, recentEvents: $recentEvents, syncedAt: $syncedAt, isStale: $isStale, key: $key}';
  }
}

/// generated route for
/// [DashboardPage]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardPage();
    },
  );
}

/// generated route for
/// [DemoEntryPage]
class DemoEntryRoute extends PageRouteInfo<void> {
  const DemoEntryRoute({List<PageRouteInfo>? children})
    : super(DemoEntryRoute.name, initialChildren: children);

  static const String name = 'DemoEntryRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DemoEntryPage();
    },
  );
}

/// generated route for
/// [SplashPage]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashPage();
    },
  );
}
