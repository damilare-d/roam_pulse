# ADR-007: Native home-screen widgets — MethodChannel bridge, pure-core UI state

## Context

docs/PRODUCT_DISCOVERY.md §3's "glance journey" and §4's pain-point table
both call for a native home-screen widget: the user checks connectivity,
data remaining, and plan expiry without opening the app. §6's constraints
scope this to Android (App Widget) and iOS (WidgetKit) — no watchOS/macOS.
§12's risk table already named the mitigation used here: "define the
Flutter-side contract and tests first; native implementations can be
minimal-but-real."

A real constraint shaped this phase as much as the product requirement
did: this project is developed on Windows, with a real Android SDK and
emulator/device available, but no macOS/Xcode. That is not a hypothetical
— it directly determines what could and couldn't be build-verified here
(see Consequences).

## Decision

- **`NativeWidgetService`** (`apps/mobile/lib/features/native_widget/`):
  a small Dart interface with `updateConnectivity(ConnectivityWidgetData)`
  and `updatePlan(PlanWidgetData)`, pushed independently rather than
  through one combined payload — mirroring `DashboardBloc`/
  `ConnectivityBloc`'s own independence (ADR-006), each pushing to the
  widget the moment it has fresh data, with no new combined-fetch
  abstraction invented just for this.
- **`MethodChannelNativeWidgetService`**: the one concrete implementation,
  a thin shell over a single `"com.roampulse.widget"` `MethodChannel` —
  deliberately untested beyond channel wiring (`network_test.dart`-style
  precedent from `ChaosInterceptor`, Phase 9); no-ops on any
  `defaultTargetPlatform` other than Android/iOS, so desktop/web dev runs
  never throw a `MissingPluginException`.
- **UI wiring**: `DashboardPage` and `ConnectivityCard` each already own
  an independent bloc (ADR-006); a `BlocConsumer`'s `listener` on each
  pushes to `NativeWidgetService` on its own `*Loaded` state, rather than
  threading a widget-service dependency into the blocs themselves —
  `packages/connectivity`/`packages/plans` stay platform-agnostic, with
  zero awareness that a home-screen widget exists.
- **Pure-core UI state on both native platforms**: exactly the same
  pattern as the Go diagnostic engine (ADR-009) and Dart's Chaos Mode
  decision function — `mapToWidgetUiState(WidgetPersistedData) ->
  WidgetUiState` is a pure, zero-I/O function on both Kotlin and Swift,
  with a thin `WidgetDataRepository`/`WidgetDataStore` persistence shell
  around it doing the only I/O (SharedPreferences on Android, a shared
  `UserDefaults` App Group suite on iOS).
- **Android**: Jetpack Glance (`GlanceAppWidget`/`GlanceAppWidgetReceiver`),
  chosen over classic `RemoteViews` for Compose-based, more directly
  testable UI-state code and because it's current platform guidance.
  `MainActivity`'s `MethodChannel` handler is the only place that touches
  both Flutter's channel and Glance's `updateAll`.
- **iOS**: WidgetKit/SwiftUI (`StaticConfiguration`, no user-configurable
  intent — the widget has nothing to configure), structurally identical
  to the Android side field-for-field. `AppDelegate`'s `MethodChannel`
  handler mirrors `MainActivity.kt`'s.
- **Formatting parity across three languages**: `WidgetTransform.kt`,
  `WidgetTransform.swift`, and `apps/mobile/lib/features/dashboard/
  format_utils.dart` independently implement the *same* rules (GB/MB
  crossover at 1000, "Expires today/tomorrow/in N days", relative-time
  wording) — deliberately not shared code (Dart, Kotlin, and Swift can't
  share a formatting library without disproportionate machinery for three
  short pure functions), but kept in lockstep by convention and this ADR
  recording that intent explicitly.

## Alternatives considered

- **One combined `WidgetPayload` covering both connectivity and plan
  data**: rejected — would need a new synchronization point where none
  exists today (nothing currently combines a connectivity fetch and a
  plan fetch into one event), forcing either an artificial combined
  fetch or a payload with awkward optional/partial fields. Two
  independent update calls, each persisted into the same underlying
  store and rendered as one merged UI, matches the app's actual
  architecture instead of fighting it.
- **`RemoteViews` instead of Glance for Android**: viable and more
  universally documented, but more verbose (hand-built `XML` layouts,
  manual `PendingIntent` wiring) for equivalent output; Glance's
  Compose-based content function is a better fit for keeping formatting
  logic in one pure, testable place.
- **Sharing formatting logic via a generated/cross-compiled artifact**
  (e.g. Kotlin Multiplatform, or code-genning Swift from Dart): rejected
  as disproportionate — three short, independently-verifiable pure
  functions are cheaper to keep in sync by convention than to introduce
  a cross-compilation toolchain for.

## Trade-offs

- Three independent implementations of the same formatting rules is a
  real maintenance cost — a rule change (e.g. the GB/MB threshold) must
  be applied in three places by hand, with only this ADR and each file's
  own doc comment as the enforcement mechanism, not a compiler.
- The widget is push-only: it updates when Flutter tells it to (on a
  successful connectivity/plan fetch), not on any periodic native
  schedule. Acceptable for a demo app with one simulated traveller and
  no background sync service; a real product might add a periodic
  WorkManager/BGTaskScheduler refresh as a backstop.

## Consequences

- **Android: built and live-verified end-to-end**, not just unit-tested.
  `WidgetTransformTest.kt` (9 cases, plain JUnit, no Robolectric — mirrors
  `chaos_action_test.dart`'s and `diagnostics_engine_test.go`'s pure-core
  testing pattern) passed on the real Android toolchain available on this
  machine. `:app:assembleDebug` succeeded, and the widget was added to a
  physical device's (Samsung Galaxy A05s, Android 14) home screen via the
  standard long-press → Widgets flow: it rendered live SoftBank/5G/Tokyo
  connectivity and plan data pulled from the real backend over the LAN,
  and updated in place after an in-app refresh — confirming the full
  `NativeWidgetService` → `MethodChannel` → `WidgetDataRepository` →
  `GlanceAppWidget.updateAll` pipeline, not just its individual pieces.
- **iOS: written, not built or verified.** There is no macOS/Xcode
  available in this development environment, so the Swift source
  (`apps/mobile/ios/RoamPulseWidget/`) has never been compiled. It was
  written to the same contract and manually traced against
  `WidgetTransformTest.kt`'s cases, but that is not the same as a passing
  test suite. `apps/mobile/ios/RoamPulseWidget/README.md` documents the
  exact manual Xcode steps (add a Widget Extension target, wire target
  membership, add the App Group entitlement) needed to actually build and
  verify it on a Mac. Recorded here honestly rather than glossed over —
  see docs/PRODUCT_DISCOVERY.md §48's "no fake seniority" principle and
  the equivalent status in docs/HOLAFLY_ROLE_MAPPING.md.
- Along the way, this phase also surfaced and fixed an unrelated,
  pre-existing environment issue: this machine's antivirus performs TLS
  interception for web scanning, which broke every JVM-based tool
  (Gradle, in particular) even though non-JVM tools (`curl`, `git`)
  worked fine, since Java maintains its own trust store separate from
  the OS certificate store. Importing the AV's root CA into each local
  JDK's `cacerts` (a standard, reversible fix for exactly this class of
  corporate/AV-proxy environment) unblocked the Android build entirely;
  this is a one-time local machine fix, not a project configuration
  change, and is not part of what other developers or CI need to do.
