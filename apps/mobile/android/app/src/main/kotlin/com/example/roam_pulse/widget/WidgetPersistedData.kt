package com.example.roam_pulse.widget

/**
 * The raw fields persisted by [WidgetDataRepository] from Flutter's
 * MethodChannel calls — one group written independently per call from
 * ConnectivityBloc's and DashboardBloc's own updates, matching the
 * Dart-side `ConnectivityWidgetData`/`PlanWidgetData` split.
 */
data class WidgetPersistedData(
    val connectionState: String?,
    val carrierName: String?,
    val technology: String?,
    val connectivityLastSyncedAt: String?,
    val destinationCity: String?,
    val countryCode: String?,
    val dataRemainingMb: Double?,
    val dataAllowanceMb: Double?,
    val daysRemaining: Int?,
)
