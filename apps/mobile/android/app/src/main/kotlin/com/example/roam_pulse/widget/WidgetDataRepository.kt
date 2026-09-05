package com.example.roam_pulse.widget

import android.content.Context

/**
 * Thin persistence shell around SharedPreferences — deliberately
 * untested beyond this file's own responsibility (reading/writing raw
 * fields), mirroring ChaosInterceptor and MethodChannelNativeWidgetService
 * on the Dart side: the actual logic ([mapToWidgetUiState]) is what's
 * unit-tested.
 */
class WidgetDataRepository(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun updateConnectivity(
        state: String,
        carrierName: String,
        technology: String,
        lastSyncedAt: String,
    ) {
        prefs.edit()
            .putString(KEY_CONNECTION_STATE, state)
            .putString(KEY_CARRIER_NAME, carrierName)
            .putString(KEY_TECHNOLOGY, technology)
            .putString(KEY_LAST_SYNCED_AT, lastSyncedAt)
            .apply()
    }

    fun updatePlan(
        destinationCity: String,
        countryCode: String,
        dataRemainingMb: Double,
        dataAllowanceMb: Double,
        daysRemaining: Int,
    ) {
        prefs.edit()
            .putString(KEY_DESTINATION_CITY, destinationCity)
            .putString(KEY_COUNTRY_CODE, countryCode)
            .putFloat(KEY_DATA_REMAINING_MB, dataRemainingMb.toFloat())
            .putFloat(KEY_DATA_ALLOWANCE_MB, dataAllowanceMb.toFloat())
            .putInt(KEY_DAYS_REMAINING, daysRemaining)
            .apply()
    }

    fun read(): WidgetPersistedData = WidgetPersistedData(
        connectionState = prefs.getString(KEY_CONNECTION_STATE, null),
        carrierName = prefs.getString(KEY_CARRIER_NAME, null),
        technology = prefs.getString(KEY_TECHNOLOGY, null),
        connectivityLastSyncedAt = prefs.getString(KEY_LAST_SYNCED_AT, null),
        destinationCity = prefs.getString(KEY_DESTINATION_CITY, null),
        countryCode = prefs.getString(KEY_COUNTRY_CODE, null),
        dataRemainingMb = if (prefs.contains(KEY_DATA_REMAINING_MB)) {
            prefs.getFloat(KEY_DATA_REMAINING_MB, 0f).toDouble()
        } else {
            null
        },
        dataAllowanceMb = if (prefs.contains(KEY_DATA_ALLOWANCE_MB)) {
            prefs.getFloat(KEY_DATA_ALLOWANCE_MB, 0f).toDouble()
        } else {
            null
        },
        daysRemaining = if (prefs.contains(KEY_DAYS_REMAINING)) {
            prefs.getInt(KEY_DAYS_REMAINING, 0)
        } else {
            null
        },
    )

    private companion object {
        const val PREFS_NAME = "roam_pulse_widget"
        const val KEY_CONNECTION_STATE = "connection_state"
        const val KEY_CARRIER_NAME = "carrier_name"
        const val KEY_TECHNOLOGY = "technology"
        const val KEY_LAST_SYNCED_AT = "last_synced_at"
        const val KEY_DESTINATION_CITY = "destination_city"
        const val KEY_COUNTRY_CODE = "country_code"
        const val KEY_DATA_REMAINING_MB = "data_remaining_mb"
        const val KEY_DATA_ALLOWANCE_MB = "data_allowance_mb"
        const val KEY_DAYS_REMAINING = "days_remaining"
    }
}
