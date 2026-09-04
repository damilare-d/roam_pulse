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
    this.downloadMbps,
    this.uploadMbps,
  });

  final ConnectivityState state;
  final NetworkInfo network;
  final String signalStrength;
  final int? latencyMs;
  final double? downloadMbps;
  final double? uploadMbps;
  final DateTime lastEventAt;

  factory ConnectivityStatus.fromJson(Map<String, dynamic> json) {
    return ConnectivityStatus(
      state: ConnectivityState.values.byName(json['state'] as String),
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
      signalStrength: json['signalStrength'] as String,
      latencyMs: json['latencyMs'] as int?,
      downloadMbps: (json['downloadMbps'] as num?)?.toDouble(),
      uploadMbps: (json['uploadMbps'] as num?)?.toDouble(),
      lastEventAt: DateTime.parse(json['lastEventAt'] as String),
    );
  }

  /// The inverse of [fromJson] — used by the offline cache
  /// (`CachingConnectivityRepository`) to persist a snapshot, not by the
  /// backend API call itself (which only ever reads).
  Map<String, dynamic> toJson() => {
    'state': state.name,
    'network': {
      'carrierName': network.carrierName,
      'technology': network.technology,
    },
    'signalStrength': signalStrength,
    'latencyMs': latencyMs,
    'downloadMbps': downloadMbps,
    'uploadMbps': uploadMbps,
    'lastEventAt': lastEventAt.toIso8601String(),
  };
}
