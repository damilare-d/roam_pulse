import Foundation

/// Must match the App Group entitlement added to both the Runner app
/// target and the RoamPulseWidget extension target in Xcode — this is
/// the iOS mechanism for two separate processes (app + extension) to
/// share data, replacing Android's single-process SharedPreferences.
private let appGroupId = "group.com.example.roamPulse.widget"

private enum WidgetDataStoreKeys {
    static let connectionState = "connection_state"
    static let carrierName = "carrier_name"
    static let technology = "technology"
    static let lastSyncedAt = "last_synced_at"
    static let destinationCity = "destination_city"
    static let countryCode = "country_code"
    static let dataRemainingMb = "data_remaining_mb"
    static let dataAllowanceMb = "data_allowance_mb"
    static let daysRemaining = "days_remaining"
}

/// Thin persistence shell around the shared `UserDefaults` suite —
/// deliberately untested beyond this file's own responsibility, mirroring
/// Android's `WidgetDataRepository`: the actual logic
/// (`mapToWidgetUiState`) is what's meant to be unit-tested.
final class WidgetDataStore {
    private let defaults: UserDefaults?

    init() {
        defaults = UserDefaults(suiteName: appGroupId)
    }

    func updateConnectivity(state: String, carrierName: String, technology: String, lastSyncedAt: String) {
        defaults?.set(state, forKey: WidgetDataStoreKeys.connectionState)
        defaults?.set(carrierName, forKey: WidgetDataStoreKeys.carrierName)
        defaults?.set(technology, forKey: WidgetDataStoreKeys.technology)
        defaults?.set(lastSyncedAt, forKey: WidgetDataStoreKeys.lastSyncedAt)
    }

    func updatePlan(
        destinationCity: String,
        countryCode: String,
        dataRemainingMb: Double,
        dataAllowanceMb: Double,
        daysRemaining: Int
    ) {
        defaults?.set(destinationCity, forKey: WidgetDataStoreKeys.destinationCity)
        defaults?.set(countryCode, forKey: WidgetDataStoreKeys.countryCode)
        defaults?.set(dataRemainingMb, forKey: WidgetDataStoreKeys.dataRemainingMb)
        defaults?.set(dataAllowanceMb, forKey: WidgetDataStoreKeys.dataAllowanceMb)
        defaults?.set(daysRemaining, forKey: WidgetDataStoreKeys.daysRemaining)
    }

    func read() -> WidgetPersistedData {
        WidgetPersistedData(
            connectionState: defaults?.string(forKey: WidgetDataStoreKeys.connectionState),
            carrierName: defaults?.string(forKey: WidgetDataStoreKeys.carrierName),
            technology: defaults?.string(forKey: WidgetDataStoreKeys.technology),
            connectivityLastSyncedAt: defaults?.string(forKey: WidgetDataStoreKeys.lastSyncedAt),
            destinationCity: defaults?.string(forKey: WidgetDataStoreKeys.destinationCity),
            countryCode: defaults?.string(forKey: WidgetDataStoreKeys.countryCode),
            dataRemainingMb: defaults?.object(forKey: WidgetDataStoreKeys.dataRemainingMb) != nil
                ? defaults?.double(forKey: WidgetDataStoreKeys.dataRemainingMb) : nil,
            dataAllowanceMb: defaults?.object(forKey: WidgetDataStoreKeys.dataAllowanceMb) != nil
                ? defaults?.double(forKey: WidgetDataStoreKeys.dataAllowanceMb) : nil,
            daysRemaining: defaults?.object(forKey: WidgetDataStoreKeys.daysRemaining) != nil
                ? defaults?.integer(forKey: WidgetDataStoreKeys.daysRemaining) : nil
        )
    }
}
