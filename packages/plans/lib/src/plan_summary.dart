import 'travel_plan.dart';

/// `GET /api/v1/plans/current` — the plan plus the backend's computed
/// "what's left" numbers (data remaining, days remaining), matching
/// backend PlanService.GetCurrentPlanSummary exactly rather than
/// recomputing them client-side.
class PlanSummary {
  const PlanSummary({
    required this.plan,
    required this.dataAllowanceMb,
    required this.dataUsedMb,
    required this.dataRemainingMb,
    required this.daysRemaining,
  });

  final TravelPlan plan;
  final double dataAllowanceMb;
  final double dataUsedMb;
  final double dataRemainingMb;
  final int daysRemaining;

  factory PlanSummary.fromJson(Map<String, dynamic> json) {
    return PlanSummary(
      plan: TravelPlan.fromJson(json['plan'] as Map<String, dynamic>),
      dataAllowanceMb: (json['dataAllowanceMb'] as num).toDouble(),
      dataUsedMb: (json['dataUsedMb'] as num).toDouble(),
      dataRemainingMb: (json['dataRemainingMb'] as num).toDouble(),
      daysRemaining: json['daysRemaining'] as int,
    );
  }
}
