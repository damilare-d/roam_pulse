import 'package:core/core.dart';
import 'package:network/network.dart';

import 'connectivity_event.dart';
import 'connectivity_status.dart';

/// The port [ConnectivityBloc] depends on. Every result is wrapped in
/// [Cached] — even a same-instant network hit — so callers can never
/// accidentally treat a value as unconditionally fresh; see
/// docs/decisions/ADR-006 for why "offline" here means *this app can't
/// reach the RoamPulse backend*, not the traveller's simulated carrier
/// connectivity ([ConnectivityState.offline]).
abstract interface class ConnectivityRepository {
  Future<Result<Cached<ConnectivityStatus>>> getStatus();

  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  });
}

/// Talks to the backend only — no caching, no offline fallback. Every
/// successful response is "fresh as of right now" by construction.
/// [CachingConnectivityRepository] wraps this to add the offline-first
/// behaviour described in ADR-006.
class HttpConnectivityRepository implements ConnectivityRepository {
  const HttpConnectivityRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async {
    final result = await _client.getJson(
      '/api/v1/connectivity',
      fromJson: ConnectivityStatus.fromJson,
    );
    return result.fold(
      (status) =>
          Ok(Cached(value: status, syncedAt: DateTime.now(), isStale: false)),
      (failure) => Err(failure),
    );
  }

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async {
    final result = await _client.getJsonList(
      '/api/v1/connectivity/events',
      fromJson: ConnectivityEvent.fromJson,
      queryParameters: {'limit': limit},
    );
    return result.fold(
      (events) =>
          Ok(Cached(value: events, syncedAt: DateTime.now(), isStale: false)),
      (failure) => Err(failure),
    );
  }
}
