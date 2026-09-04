import 'package:core/core.dart';
import 'package:network/network.dart';

import 'connectivity_event.dart';
import 'connectivity_status.dart';

/// The port [ConnectivityBloc] depends on. `HttpConnectivityRepository` is
/// the only implementation today (`RemoteConnectivityDataSource` in the
/// conceptual diagram, docs/ARCHITECTURE.md section 8); Phase 6 adds a
/// cached/offline-aware implementation behind this same interface without
/// the bloc changing.
abstract interface class ConnectivityRepository {
  Future<Result<ConnectivityStatus>> getStatus();

  Future<Result<List<ConnectivityEvent>>> getRecentEvents({int limit = 20});
}

class HttpConnectivityRepository implements ConnectivityRepository {
  const HttpConnectivityRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<ConnectivityStatus>> getStatus() {
    return _client.getJson(
      '/api/v1/connectivity',
      fromJson: ConnectivityStatus.fromJson,
    );
  }

  @override
  Future<Result<List<ConnectivityEvent>>> getRecentEvents({int limit = 20}) {
    return _client.getJsonList(
      '/api/v1/connectivity/events',
      fromJson: ConnectivityEvent.fromJson,
      queryParameters: {'limit': limit},
    );
  }
}
