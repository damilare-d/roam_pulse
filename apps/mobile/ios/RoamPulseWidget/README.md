# RoamPulseWidget (iOS WidgetKit) — manual Xcode setup required

This directory's Swift source was written on Windows, with no macOS/Xcode
available in this project's development environment. It has **not** been
compiled, run, or tested — unlike the Android widget (Jetpack Glance),
which was built and live-verified end-to-end (see
`docs/HOLAFLY_ROLE_MAPPING.md` and ADR-007). Treat this as a correct-effort
implementation to wire up and verify on a Mac, not a working extension yet.

## What's here

- `Shared/WidgetUiState.swift`, `WidgetPersistedData.swift` — plain data
  types, no Foundation dependencies beyond basics.
- `Shared/WidgetTransform.swift` — the pure `mapToWidgetUiState` function
  (mirrors `apps/mobile/android/.../widget/WidgetTransform.kt` exactly).
  **Not unit-tested** — there's no `swift test`/Xcode test runner here.
  If porting `WidgetTransformTest.kt`'s 9 cases to an XCTest target,
  that's the first thing to do once this is opened on a Mac.
- `Shared/WidgetDataStore.swift` — thin persistence shell over a shared
  `UserDefaults` App Group suite (`group.com.example.roamPulse.widget`).
- `RoamPulseWidget.swift` — the actual `Widget`/`TimelineProvider`/
  `WidgetBundle` — this is the file Xcode needs as the extension
  target's entry point.
- `apps/mobile/ios/Runner/AppDelegate.swift` (already edited, not in this
  folder) adds the `"com.roampulse.widget"` MethodChannel handler that
  Flutter's `MethodChannelNativeWidgetService` calls into.

## Manual steps to actually build this (on a Mac, in Xcode)

1. Open `Runner.xcworkspace` (not `.xcodeproj`) in Xcode.
2. File → New → Target → **Widget Extension**. Name it `RoamPulseWidget`,
   uncheck "Include Configuration Intent" (this is a `StaticConfiguration`
   widget, no user-configurable intent).
3. Delete the placeholder `.swift` file Xcode generates for the new
   target and add `RoamPulseWidget.swift` from this folder instead.
4. Add the three files under `Shared/` to **both** target memberships —
   the new `RoamPulseWidget` extension target *and* the existing
   `Runner` app target (`AppDelegate.swift` needs `WidgetDataStore` too).
5. Enable the **App Groups** capability on both the `Runner` target and
   the `RoamPulseWidget` target, and add the same group:
   `group.com.example.roamPulse.widget` (must match the constant in
   `WidgetDataStore.swift`).
6. Build once for a simulator or device to confirm it compiles; add the
   widget to a Home Screen via the long-press → Edit Home Screen → "+"
   flow to see it render.
7. Port `WidgetTransformTest.kt`'s cases to an XCTest target against
   `mapToWidgetUiState`, and update `docs/HOLAFLY_ROLE_MAPPING.md`'s iOS
   row from "written, unverified" to a live-verified status once you've
   confirmed it on a simulator/device.
