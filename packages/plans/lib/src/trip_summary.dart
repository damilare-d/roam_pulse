import 'package:connectivity/connectivity.dart' show NetworkInfo;

import 'destination.dart';
import 'travel_plan.dart';
import 'traveller_profile.dart';

/// `GET /api/v1/trips/current` — "where am I and on what network", the
/// identity view of a trip. Reuses [NetworkInfo] from `packages/connectivity`
/// rather than redefining an identical carrier/technology pair.
class TripSummary {
  const TripSummary({
    required this.traveller,
    required this.destination,
    required this.network,
    required this.plan,
  });

  final TravellerProfile traveller;
  final Destination destination;
  final NetworkInfo network;
  final TravelPlan plan;

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      traveller: TravellerProfile.fromJson(
        json['traveller'] as Map<String, dynamic>,
      ),
      destination: Destination.fromJson(
        json['destination'] as Map<String, dynamic>,
      ),
      network: NetworkInfo.fromJson(json['network'] as Map<String, dynamic>),
      plan: TravelPlan.fromJson(json['plan'] as Map<String, dynamic>),
    );
  }
}
