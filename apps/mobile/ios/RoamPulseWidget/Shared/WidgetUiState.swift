import Foundation

/// Everything the widget renders, already formatted — the output of
/// `mapToWidgetUiState`. Mirrors Android's `WidgetUiState`/`ConnectionTone`
/// (apps/mobile/android/.../widget/WidgetUiState.kt) field-for-field, so
/// both platforms render the same information from the same contract,
/// even though neither shares code with the other.
struct WidgetUiState {
    let connectionLabel: String
    let connectionTone: ConnectionTone
    let carrierLine: String?
    let destinationLine: String?
    let dataRemainingLabel: String?
    let dataPercentRemaining: Int?
    let expiryLabel: String?
    let lastUpdatedLabel: String?
}

enum ConnectionTone {
    case positive
    case warning
    case negative
    case neutral
}
