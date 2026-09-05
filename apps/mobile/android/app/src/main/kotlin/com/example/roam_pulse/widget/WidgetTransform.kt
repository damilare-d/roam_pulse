package com.example.roam_pulse.widget

import java.time.Duration
import java.time.Instant
import kotlin.math.roundToInt

/**
 * Maps raw persisted widget data to what actually gets rendered — mirrors
 * apps/mobile/lib/features/dashboard/format_utils.dart's rules exactly
 * (data-remaining/expiry formatting) so the widget and the in-app
 * dashboard never disagree about wording, even though the logic can't
 * literally be shared across Dart and Kotlin. [now] is a parameter (not
 * `Instant.now()` inline) so relative-time formatting is deterministic
 * in tests.
 */
fun mapToWidgetUiState(
    data: WidgetPersistedData,
    now: Instant = Instant.now(),
): WidgetUiState {
    val connectionLabel = when (data.connectionState) {
        "connected" -> "Connected"
        "degraded" -> "Degraded connection"
        "offline" -> "Offline"
        "error" -> "Connection error"
        "connecting" -> "Connecting…"
        "synchronizing" -> "Syncing…"
        else -> "Unknown"
    }
    val connectionTone = when (data.connectionState) {
        "connected" -> ConnectionTone.POSITIVE
        "degraded" -> ConnectionTone.WARNING
        "offline", "error" -> ConnectionTone.NEGATIVE
        else -> ConnectionTone.NEUTRAL
    }

    val carrierLine = if (data.carrierName != null && data.technology != null) {
        "${data.carrierName} · ${data.technology}"
    } else {
        null
    }

    val dataPercentRemaining =
        if (data.dataRemainingMb != null && data.dataAllowanceMb != null && data.dataAllowanceMb > 0) {
            ((data.dataRemainingMb / data.dataAllowanceMb) * 100).roundToInt().coerceIn(0, 100)
        } else {
            null
        }

    val expiryLabel = data.daysRemaining?.let {
        when {
            it <= 0 -> "Expires today"
            it == 1 -> "Expires tomorrow"
            else -> "Expires in $it days"
        }
    }

    return WidgetUiState(
        connectionLabel = connectionLabel,
        connectionTone = connectionTone,
        carrierLine = carrierLine,
        destinationLine = data.destinationCity,
        dataRemainingLabel = data.dataRemainingMb?.let(::formatMegabytes),
        dataPercentRemaining = dataPercentRemaining,
        expiryLabel = expiryLabel,
        lastUpdatedLabel = data.connectivityLastSyncedAt?.let { formatRelative(it, now) },
    )
}

/**
 * "X.X GB" once it crosses 1000 MB, otherwise "X MB" — same rule as
 * format_utils.dart's `formatMegabytes`.
 */
fun formatMegabytes(megabytes: Double): String {
    return if (megabytes >= 1000) {
        "%.1f GB".format(megabytes / 1000)
    } else {
        "${megabytes.roundToInt()} MB"
    }
}

private fun formatRelative(isoTimestamp: String, now: Instant): String? {
    val since = runCatching { Instant.parse(isoTimestamp) }.getOrNull() ?: return null
    val elapsed = Duration.between(since, now)
    return when {
        elapsed < Duration.ofMinutes(1) -> "moments ago"
        elapsed < Duration.ofHours(1) -> {
            val minutes = elapsed.toMinutes()
            "$minutes ${if (minutes == 1L) "minute" else "minutes"} ago"
        }
        elapsed < Duration.ofDays(1) -> {
            val hours = elapsed.toHours()
            "$hours ${if (hours == 1L) "hour" else "hours"} ago"
        }
        else -> {
            val days = elapsed.toDays()
            "$days ${if (days == 1L) "day" else "days"} ago"
        }
    }
}
