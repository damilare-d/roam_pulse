import 'chaos_condition.dart';

/// What [ChaosInterceptor] should do to a given request. Kept as a pure,
/// no-Dio-dependency sealed class specifically so [decideChaosAction] is
/// unit-testable without any Dio/network machinery — the interceptor
/// itself is a thin translation layer over this decision, not tested
/// exhaustively (mirrors the diagnostic engine's pure-core pattern,
/// ADR-009).
sealed class ChaosAction {
  const ChaosAction();
}

/// Let the request through unchanged.
class ChaosPassThrough extends ChaosAction {
  const ChaosPassThrough();
}

/// Let the request through, but only after an artificial delay — used for
/// both "slow network" and "delayed API response", since from the
/// interceptor's point of view they're the same action with different
/// durations.
class ChaosDelay extends ChaosAction {
  const ChaosDelay(this.duration);

  final Duration duration;
}

/// Fail before any real network call is made, as a connection error (the
/// "offline" scenario).
class ChaosRejectOffline extends ChaosAction {
  const ChaosRejectOffline();
}

/// Fail before any real network call is made, as a timeout.
class ChaosRejectTimeout extends ChaosAction {
  const ChaosRejectTimeout();
}

/// Fail as if the server responded with a 500 — reuses
/// packages/network's existing `mapDioException` fallback-by-status
/// logic rather than needing a new error-classification path.
class ChaosRejectServerError extends ChaosAction {
  const ChaosRejectServerError();
}

/// Succeed, but with a response body missing the `data` key — exercises
/// [ApiClient]'s existing `ParsingFailure` path the same way a genuinely
/// malformed backend response would.
class ChaosResolveEmpty extends ChaosAction {
  const ChaosResolveEmpty();
}

/// The single source of truth for "given these two dials, what happens to
/// this request" — a network condition other than [NetworkCondition.normal]
/// always wins, matching how a real device works: you can't get a 500
/// from a server you can't reach.
ChaosAction decideChaosAction({
  required NetworkCondition network,
  required ApiCondition api,
}) {
  switch (network) {
    case NetworkCondition.offline:
      return const ChaosRejectOffline();
    case NetworkCondition.timeout:
      return const ChaosRejectTimeout();
    case NetworkCondition.slow:
      return const ChaosDelay(Duration(seconds: 3));
    case NetworkCondition.normal:
      break;
  }

  switch (api) {
    case ApiCondition.serverError:
      return const ChaosRejectServerError();
    case ApiCondition.emptyResponse:
      return const ChaosResolveEmpty();
    case ApiCondition.delayed:
      return const ChaosDelay(Duration(seconds: 2));
    case ApiCondition.normal:
      return const ChaosPassThrough();
  }
}
