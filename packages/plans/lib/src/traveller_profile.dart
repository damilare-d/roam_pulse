class TravellerProfile {
  const TravellerProfile({
    required this.id,
    required this.displayName,
    required this.homeCountry,
  });

  final String id;
  final String displayName;
  final String homeCountry;

  factory TravellerProfile.fromJson(Map<String, dynamic> json) {
    return TravellerProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      homeCountry: json['homeCountry'] as String,
    );
  }
}
