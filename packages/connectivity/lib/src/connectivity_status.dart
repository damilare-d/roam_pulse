import 'connectivity_state.dart';
import 'network_info.dart';

/// The `GET /api/v1/connectivity` response: current state plus the
/// connection-quality snapshot from the traveller's latest network
/// session (see backend ConnectivityService.GetStatus — state comes from
/// the event stream, quality from the session).
class ConnectivityStatus {
  const ConnectivityStatus({
    required this.state,
    required this.network,
    required this.signalStrength,
    required this.lastEventAt,
    this.latencyMs,
  });

  final ConnectivityState state;
  final NetworkInfo network;
  final String signalStrength;
  final int? latencyMs;
  final DateTime lastEventAt;

  factory ConnectivityStatus.fromJson(Map<String, dynamic> json) {
    return ConnectivityStatus(
      state: ConnectivityState.values.byName(json['state'] as String),
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
      signalStrength: json['signalStrength'] as String,
      latencyMs: json['latencyMs'] as int?,
      lastEventAt: DateTime.parse(json['lastEventAt'] as String),
    );
  }
}
