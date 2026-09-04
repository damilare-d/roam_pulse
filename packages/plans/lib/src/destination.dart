class Destination {
  const Destination({
    required this.id,
    required this.countryCode,
    required this.city,
    required this.timezone,
  });

  final String id;
  final String countryCode;
  final String city;
  final String timezone;

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as String,
      countryCode: json['countryCode'] as String,
      city: json['city'] as String,
      timezone: json['timezone'] as String,
    );
  }
}
