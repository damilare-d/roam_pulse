enum PlanStatus { upcoming, active, completed, expired }

class TravelPlan {
  const TravelPlan({
    required this.id,
    required this.destinationId,
    required this.startsAt,
    required this.expiresAt,
    required this.dataAllowanceMb,
    required this.status,
  });

  final String id;
  final String destinationId;
  final DateTime startsAt;
  final DateTime expiresAt;
  final int dataAllowanceMb;
  final PlanStatus status;

  factory TravelPlan.fromJson(Map<String, dynamic> json) {
    return TravelPlan(
      id: json['id'] as String,
      destinationId: json['destinationId'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      dataAllowanceMb: json['dataAllowanceMb'] as int,
      status: PlanStatus.values.byName(json['status'] as String),
    );
  }
}
