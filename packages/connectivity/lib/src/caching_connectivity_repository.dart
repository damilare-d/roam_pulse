import 'package:core/core.dart';
import 'package:storage/storage.dart';

import 'connectivity_event.dart';
import 'connectivity_repository.dart';
import 'connectivity_state.dart';
import 'connectivity_status.dart';
import 'network_info.dart';

/// Offline-first: network-first with a cache fallback, not full
/// stale-while-revalidate — see ADR-006 for why that's a deliberate scope
/// decision, not an oversight.
///
/// ONLINE:  remote succeeds → cache is written → fresh Cached returned.
/// OFFLINE: remote fails    → cache is read     → stale Cached returned
///          (or the original failure, if there's nothing cached yet).
class CachingConnectivityRepository implements ConnectivityRepository {
  CachingConnectivityRepository(
    this._remote,
    KeyValueStore store, {
    Duration ttl = const Duration(minutes: 5),
  }) : _statusCache = Cache<ConnectivityStatus>(
         store: store,
         key: 'connectivity.status',
         ttl: ttl,
         fromJson: _statusFromJson,
         toJson: _statusToJson,
       ),
       _eventsCache = Cache<List<ConnectivityEvent>>(
         store: store,
         key: 'connectivity.events',
         ttl: ttl,
         fromJson: _eventsFromJson,
         toJson: _eventsToJson,
       );

  final ConnectivityRepository _remote;
  final Cache<ConnectivityStatus> _statusCache;
  final Cache<List<ConnectivityEvent>> _eventsCache;

  @override
  Future<Result<Cached<ConnectivityStatus>>> getStatus() async {
    final remoteResult = await _remote.getStatus();
    switch (remoteResult) {
      case Ok(:final value):
        await _statusCache.write(value.value);
        return remoteResult;
      case Err(:final failure):
        final cached = await _statusCache.read();
        return cached != null ? Ok(cached) : Err(failure);
    }
  }

  @override
  Future<Result<Cached<List<ConnectivityEvent>>>> getRecentEvents({
    int limit = 20,
  }) async {
    final remoteResult = await _remote.getRecentEvents(limit: limit);
    switch (remoteResult) {
      case Ok(:final value):
        await _eventsCache.write(value.value);
        return remoteResult;
      case Err(:final failure):
        final cached = await _eventsCache.read();
        return cached != null ? Ok(cached) : Err(failure);
    }
  }
}

Map<String, dynamic> _statusToJson(ConnectivityStatus status) => {
  'state': status.state.name,
  'network': {
    'carrierName': status.network.carrierName,
    'technology': status.network.technology,
  },
  'signalStrength': status.signalStrength,
  'latencyMs': status.latencyMs,
  'lastEventAt': status.lastEventAt.toIso8601String(),
};

ConnectivityStatus _statusFromJson(Map<String, dynamic> json) =>
    ConnectivityStatus(
      state: ConnectivityState.values.byName(json['state'] as String),
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
      signalStrength: json['signalStrength'] as String,
      latencyMs: json['latencyMs'] as int?,
      lastEventAt: DateTime.parse(json['lastEventAt'] as String),
    );

Map<String, dynamic> _eventsToJson(List<ConnectivityEvent> events) => {
  'events': events
      .map(
        (e) => {
          'occurredAt': e.occurredAt.toIso8601String(),
          'fromState': e.fromState.name,
          'toState': e.toState.name,
          'reason': e.reason,
        },
      )
      .toList(),
};

List<ConnectivityEvent> _eventsFromJson(Map<String, dynamic> json) {
  final raw = json['events'] as List;
  return raw
      .cast<Map<String, dynamic>>()
      .map(
        (e) => ConnectivityEvent(
          occurredAt: DateTime.parse(e['occurredAt'] as String),
          fromState: ConnectivityState.values.byName(e['fromState'] as String),
          toState: ConnectivityState.values.byName(e['toState'] as String),
          reason: e['reason'] as String?,
        ),
      )
      .toList();
}
