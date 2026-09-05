package com.example.roam_pulse.widget

import java.time.Instant
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Plain JUnit — no Robolectric/instrumentation needed, since
 * [mapToWidgetUiState] touches no Android framework type. Mirrors
 * chaos_action_test.dart and diagnostics_engine_test.go: the pure-core
 * layer is what's exhaustively tested; the SharedPreferences/Glance
 * shells around it are not.
 */
class WidgetTransformTest {

    @Test
    fun `maps a healthy connected state to a positive label and tone`() {
        val data = WidgetPersistedData(
            connectionState = "connected",
            carrierName = "SoftBank",
            technology = "5G",
            connectivityLastSyncedAt = null,
            destinationCity = "Tokyo",
            countryCode = "JP",
            dataRemainingMb = 6800.0,
            dataAllowanceMb = 8000.0,
            daysRemaining = 3,
        )

        val state = mapToWidgetUiState(data)

        assertEquals("Connected", state.connectionLabel)
        assertEquals(ConnectionTone.POSITIVE, state.connectionTone)
        assertEquals("SoftBank · 5G", state.carrierLine)
        assertEquals("Tokyo", state.destinationLine)
        assertEquals("6.8 GB", state.dataRemainingLabel)
        assertEquals(85, state.dataPercentRemaining)
        assertEquals("Expires in 3 days", state.expiryLabel)
    }

    @Test
    fun `maps offline state to a negative tone`() {
        val state = mapToWidgetUiState(emptyData().copy(connectionState = "offline"))
        assertEquals("Offline", state.connectionLabel)
        assertEquals(ConnectionTone.NEGATIVE, state.connectionTone)
    }

    @Test
    fun `maps degraded state to a warning tone`() {
        val state = mapToWidgetUiState(emptyData().copy(connectionState = "degraded"))
        assertEquals(ConnectionTone.WARNING, state.connectionTone)
    }

    @Test
    fun `maps an unrecognized or missing state to neutral unknown`() {
        val state = mapToWidgetUiState(emptyData())
        assertEquals("Unknown", state.connectionLabel)
        assertEquals(ConnectionTone.NEUTRAL, state.connectionTone)
    }

    @Test
    fun `formats data remaining under 1000 MB in whole megabytes`() {
        assertEquals("450 MB", formatMegabytes(450.0))
    }

    @Test
    fun `formats data remaining at or above 1000 MB in gigabytes`() {
        assertEquals("1.2 GB", formatMegabytes(1200.0))
    }

    @Test
    fun `expiry label matches the today tomorrow days-remaining rules`() {
        assertEquals("Expires today", mapToWidgetUiState(emptyData().copy(daysRemaining = 0)).expiryLabel)
        assertEquals("Expires tomorrow", mapToWidgetUiState(emptyData().copy(daysRemaining = 1)).expiryLabel)
        assertEquals("Expires in 5 days", mapToWidgetUiState(emptyData().copy(daysRemaining = 5)).expiryLabel)
    }

    @Test
    fun `data percent remaining is null without both remaining and allowance`() {
        assertNull(mapToWidgetUiState(emptyData()).dataPercentRemaining)
    }

    @Test
    fun `last updated label reflects elapsed time relative to now`() {
        val now = Instant.parse("2026-09-04T12:00:00Z")
        val fiveMinutesAgo = "2026-09-04T11:55:00Z"

        val state = mapToWidgetUiState(
            emptyData().copy(connectivityLastSyncedAt = fiveMinutesAgo),
            now,
        )

        assertEquals("5 minutes ago", state.lastUpdatedLabel)
    }

    private fun emptyData() = WidgetPersistedData(
        connectionState = null,
        carrierName = null,
        technology = null,
        connectivityLastSyncedAt = null,
        destinationCity = null,
        countryCode = null,
        dataRemainingMb = null,
        dataAllowanceMb = null,
        daysRemaining = null,
    )
}
