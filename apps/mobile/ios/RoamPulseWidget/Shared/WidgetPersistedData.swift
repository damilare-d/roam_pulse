import Foundation

/// The raw fields persisted by `WidgetDataStore` from Flutter's
/// MethodChannel calls — one group written independently per call from
/// ConnectivityBloc's and DashboardBloc's own updates, matching the
/// Dart-side `ConnectivityWidgetData`/`PlanWidgetData` split and
/// Android's `WidgetPersistedData`.
struct WidgetPersistedData {
    let connectionState: String?
    let carrierName: String?
    let technology: String?
    let connectivityLastSyncedAt: String?
    let destinationCity: String?
    let countryCode: String?
    let dataRemainingMb: Double?
    let dataAllowanceMb: Double?
    let daysRemaining: Int?
}
