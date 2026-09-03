/// A minimal traveller profile model, scoped to what the dashboard shell
/// needs to prove end-to-end connectivity to the backend. This moves into
/// a proper `packages/plans` domain model in Phase 7 once the full
/// dashboard (usage, plan, destination, connection health) is built.
class TravellerProfile {
  const TravellerProfile({
    required this.displayName,
    required this.homeCountry,
  });

  final String displayName;
  final String homeCountry;

  factory TravellerProfile.fromJson(Map<String, dynamic> json) {
    return TravellerProfile(
      displayName: json['displayName'] as String,
      homeCountry: json['homeCountry'] as String,
    );
  }
}
