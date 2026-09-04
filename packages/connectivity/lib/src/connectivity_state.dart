/// The connectivity state machine — never represent connectivity with an
/// arbitrary boolean (docs/ARCHITECTURE.md section 4). Values mirror the
/// backend's domain.ConnectivityState exactly (Unknown, Connecting,
/// Connected, Degraded, Offline, Synchronizing, Error), so JSON decoding
/// is a direct `ConnectivityState.values.byName(...)`.
enum ConnectivityState {
  unknown,
  connecting,
  connected,
  degraded,
  offline,
  synchronizing,
  error,
}
