package com.example.roam_pulse.widget

/**
 * Everything the widget renders, already formatted — the output of
 * [mapToWidgetUiState]. Kept free of Android framework types so it (and
 * the pure function that produces it) can be unit-tested with plain
 * JUnit, no Robolectric/instrumentation — the same pure-core pattern as
 * the Go diagnostic engine and Dart's Chaos Mode decision function.
 */
data class WidgetUiState(
    val connectionLabel: String,
    val connectionTone: ConnectionTone,
    val carrierLine: String?,
    val destinationLine: String?,
    val dataRemainingLabel: String?,
    val dataPercentRemaining: Int?,
    val expiryLabel: String?,
    val lastUpdatedLabel: String?,
)

enum class ConnectionTone { POSITIVE, WARNING, NEGATIVE, NEUTRAL }
