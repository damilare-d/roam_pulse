import SwiftUI
import WidgetKit

/// The "glance journey" from docs/PRODUCT_DISCOVERY.md §3 — the user
/// checks connectivity/data/expiry from the home screen without opening
/// the app. Structurally mirrors Android's RoamPulseWidget.kt: reads
/// whatever `WidgetDataStore` last persisted (written by AppDelegate's
/// MethodChannel handler) and renders it through the pure
/// `mapToWidgetUiState`; this file stays a thin composition shell with
/// no formatting logic of its own.
struct RoamPulseEntry: TimelineEntry {
    let date: Date
    let uiState: WidgetUiState
}

struct RoamPulseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoamPulseEntry {
        RoamPulseEntry(date: Date(), uiState: mapToWidgetUiState(emptyData()))
    }

    func getSnapshot(in context: Context, completion: @escaping (RoamPulseEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoamPulseEntry>) -> Void) {
        // The widget only changes when Flutter pushes new data via the
        // MethodChannel (which calls WidgetCenter.reloadAllTimelines()) —
        // there's no periodic refresh schedule beyond that push.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> RoamPulseEntry {
        RoamPulseEntry(date: Date(), uiState: mapToWidgetUiState(WidgetDataStore().read()))
    }

    private func emptyData() -> WidgetPersistedData {
        WidgetPersistedData(
            connectionState: nil, carrierName: nil, technology: nil,
            connectivityLastSyncedAt: nil, destinationCity: nil, countryCode: nil,
            dataRemainingMb: nil, dataAllowanceMb: nil, daysRemaining: nil
        )
    }
}

struct RoamPulseWidgetEntryView: View {
    var entry: RoamPulseTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.uiState.connectionLabel)
                .font(.headline)
                .foregroundColor(toneColor(entry.uiState.connectionTone))
            if let carrierLine = entry.uiState.carrierLine {
                Text(carrierLine).font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 4)
            if let destination = entry.uiState.destinationLine {
                Text(destination).font(.subheadline).fontWeight(.medium)
            }
            if let remaining = entry.uiState.dataRemainingLabel {
                Text("\(remaining) remaining").font(.title3).fontWeight(.bold)
            }
            if let expiry = entry.uiState.expiryLabel {
                Text(expiry).font(.caption).foregroundColor(.secondary)
            }
            if let updated = entry.uiState.lastUpdatedLabel {
                Text("Updated \(updated)").font(.caption2).foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private func toneColor(_ tone: ConnectionTone) -> Color {
    switch tone {
    case .positive: return Color(red: 0.18, green: 0.49, blue: 0.20)
    case .warning: return Color(red: 0.98, green: 0.66, blue: 0.15)
    case .negative: return Color(red: 0.78, green: 0.16, blue: 0.16)
    case .neutral: return Color(red: 0.38, green: 0.38, blue: 0.38)
    }
}

struct RoamPulseWidget: Widget {
    let kind: String = "RoamPulseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoamPulseTimelineProvider()) { entry in
            RoamPulseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("RoamPulse")
        .description("Shows your connection status and remaining data at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RoamPulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoamPulseWidget()
    }
}
