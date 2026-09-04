import 'connectivity_state.dart';

/// One row from the backend's `connectivity_events` table — a historical
/// state transition, as returned by `GET /api/v1/connectivity/events`.
///
/// Named to match the backend exactly even though "Event" also means
/// something in Bloc's own vocabulary — see [ConnectivityBloc]'s doc
/// comment for how that naming collision is resolved.
class ConnectivityEvent {
  const ConnectivityEvent({
    required this.occurredAt,
    required this.fromState,
    required this.toState,
    this.reason,
  });

  final DateTime occurredAt;
  final ConnectivityState fromState;
  final ConnectivityState toState;
  final String? reason;

  factory ConnectivityEvent.fromJson(Map<String, dynamic> json) {
    return ConnectivityEvent(
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      fromState: ConnectivityState.values.byName(json['fromState'] as String),
      toState: ConnectivityState.values.byName(json['toState'] as String),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'occurredAt': occurredAt.toIso8601String(),
    'fromState': fromState.name,
    'toState': toState.name,
    'reason': reason,
  };
}
