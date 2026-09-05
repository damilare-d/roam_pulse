/// What the home-screen widget shows about the current plan — see
/// [ConnectivityWidgetData]'s doc comment for why this stays a separate
/// payload rather than one combined shape: it mirrors DashboardBloc and
/// ConnectivityBloc's own independence (ADR-006), each pushing to the
/// widget the moment it has fresh data.
class PlanWidgetData {
  const PlanWidgetData({
    required this.destinationCity,
    required this.countryCode,
    required this.dataRemainingMb,
    required this.dataAllowanceMb,
    required this.daysRemaining,
  });

  final String destinationCity;
  final String countryCode;
  final double dataRemainingMb;
  final double dataAllowanceMb;
  final int daysRemaining;

  Map<String, Object?> toJson() => {
    'destinationCity': destinationCity,
    'countryCode': countryCode,
    'dataRemainingMb': dataRemainingMb,
    'dataAllowanceMb': dataAllowanceMb,
    'daysRemaining': daysRemaining,
  };
}
