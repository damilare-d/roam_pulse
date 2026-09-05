import Foundation

/// Maps raw persisted widget data to what actually gets rendered —
/// mirrors apps/mobile/lib/features/dashboard/format_utils.dart's rules
/// exactly (data-remaining/expiry formatting), and Android's
/// WidgetTransform.kt structurally, so all three platforms agree on
/// wording without sharing code. `now` is a parameter (not `Date()`
/// inline) so relative-time formatting is deterministic in tests.
///
/// NOTE: unlike its Android counterpart, this function has not been
/// unit-tested — there is no macOS/Xcode toolchain available in this
/// project's development environment to run `swift test` or an Xcode
/// test target. It was written to the same logic and manually traced
/// against WidgetTransformTest.kt's cases, but is unverified. See
/// docs/HOLAFLY_ROLE_MAPPING.md and ADR-007 for the honest status.
func mapToWidgetUiState(_ data: WidgetPersistedData, now: Date = Date()) -> WidgetUiState {
    let connectionLabel: String
    switch data.connectionState {
    case "connected": connectionLabel = "Connected"
    case "degraded": connectionLabel = "Degraded connection"
    case "offline": connectionLabel = "Offline"
    case "error": connectionLabel = "Connection error"
    case "connecting": connectionLabel = "Connecting…"
    case "synchronizing": connectionLabel = "Syncing…"
    default: connectionLabel = "Unknown"
    }

    let connectionTone: ConnectionTone
    switch data.connectionState {
    case "connected": connectionTone = .positive
    case "degraded": connectionTone = .warning
    case "offline", "error": connectionTone = .negative
    default: connectionTone = .neutral
    }

    let carrierLine: String?
    if let carrier = data.carrierName, let technology = data.technology {
        carrierLine = "\(carrier) · \(technology)"
    } else {
        carrierLine = nil
    }

    var dataPercentRemaining: Int?
    if let remaining = data.dataRemainingMb, let allowance = data.dataAllowanceMb, allowance > 0 {
        dataPercentRemaining = min(100, max(0, Int((remaining / allowance * 100).rounded())))
    }

    let expiryLabel: String? = data.daysRemaining.map { days in
        if days <= 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        return "Expires in \(days) days"
    }

    let lastUpdatedLabel = data.connectivityLastSyncedAt.flatMap { formatRelative($0, now: now) }

    return WidgetUiState(
        connectionLabel: connectionLabel,
        connectionTone: connectionTone,
        carrierLine: carrierLine,
        destinationLine: data.destinationCity,
        dataRemainingLabel: data.dataRemainingMb.map(formatMegabytes),
        dataPercentRemaining: dataPercentRemaining,
        expiryLabel: expiryLabel,
        lastUpdatedLabel: lastUpdatedLabel
    )
}

/// "X.X GB" once it crosses 1000 MB, otherwise "X MB" — same rule as
/// format_utils.dart's `formatMegabytes` and Android's `formatMegabytes`.
func formatMegabytes(_ megabytes: Double) -> String {
    if megabytes >= 1000 {
        return String(format: "%.1f GB", megabytes / 1000)
    }
    return "\(Int(megabytes.rounded())) MB"
}

private func formatRelative(_ isoTimestamp: String, now: Date) -> String? {
    guard let since = parseISO8601(isoTimestamp) else { return nil }
    let elapsed = now.timeIntervalSince(since)
    switch elapsed {
    case ..<60:
        return "moments ago"
    case ..<3600:
        let minutes = Int(elapsed / 60)
        return "\(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
    case ..<86400:
        let hours = Int(elapsed / 3600)
        return "\(hours) \(hours == 1 ? "hour" : "hours") ago"
    default:
        let days = Int(elapsed / 86400)
        return "\(days) \(days == 1 ? "day" : "days") ago"
    }
}

/// Dart's `toIso8601String()` includes fractional seconds
/// ("2026-09-04T12:30:00.000Z"), which `ISO8601DateFormatter` only
/// parses with `.withFractionalSeconds` set — falls back to the plain
/// format for safety.
private func parseISO8601(_ value: String) -> Date? {
    let withFractional = ISO8601DateFormatter()
    withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = withFractional.date(from: value) {
        return date
    }
    let plain = ISO8601DateFormatter()
    plain.formatOptions = [.withInternetDateTime]
    return plain.date(from: value)
}
