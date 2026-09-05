/// What the home-screen widget shows about the current connection — the
/// Flutter-side half of the contract with [NativeWidgetService]. Carries
/// the raw domain state rather than a pre-formatted label so each native
/// platform maps it to its own tone/label independently, the same way
/// `ConnectivityCard` does on the Flutter side (see its doc comment)
/// rather than sharing formatting logic that can't actually be shared
/// across languages.
class ConnectivityWidgetData {
  const ConnectivityWidgetData({
    required this.state,
    required this.carrierName,
    required this.technology,
    required this.lastSyncedAt,
  });

  final String state;
  final String carrierName;
  final String technology;
  final DateTime lastSyncedAt;

  Map<String, Object?> toJson() => {
    'state': state,
    'carrierName': carrierName,
    'technology': technology,
    'lastSyncedAt': lastSyncedAt.toIso8601String(),
  };
}
