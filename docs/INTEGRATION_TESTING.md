# Integration testing

Five end-to-end scenarios, built directly off the primary user journey in
`docs/PRODUCT_DISCOVERY.md` §3:

```text
Open RoamPulse → demo mode → trip → connectivity → data remaining →
plan expiry → network → usage → inspect connection quality → outage →
degraded detection → cached/offline state → diagnostics → likely issue →
AI contextual guidance → network restored → sync → native widget updates
```

Each scenario is a real Flutter `integration_test`, driving the actual
`RoamPulseApp` widget tree against the actual running backend — no mocked
repositories, no fake HTTP client. These are integration tests in the
literal sense: `go run ./cmd/api` and Postgres must be up before any of
them will pass.

| File | Journey steps covered |
|---|---|
| `golden_path_test.dart` | Demo sign-in → trip, connectivity, usage all load from the real backend; both native widget channels receive real data |
| `offline_cache_test.dart` | Outage → cached data with a stale banner (not an error) → restore → clean refresh |
| `diagnostics_test.dart` | Connection details → run diagnostics → the real deterministic engine's healthy result |
| `ai_recovery_test.dart` | Diagnostics → "Get AI recommendation" → an honestly-labelled fallback (no `ANTHROPIC_API_KEY` provisioned — see ADR-008) |
| `sync_and_widget_test.dart` | A second successful sync pushes a second, newer native widget update — proving this is a repeatable cycle, not a one-time push |

## Running them

```bash
# Terminal 1
cd backend/api && go run ./cmd/api

# Terminal 2 (each file run separately)
cd apps/mobile
flutter test integration_test/golden_path_test.dart -d windows
flutter test integration_test/offline_cache_test.dart -d windows
flutter test integration_test/diagnostics_test.dart -d windows
flutter test integration_test/ai_recovery_test.dart -d windows
flutter test integration_test/sync_and_widget_test.dart -d windows
```

Swap `-d windows` for `-d <device-id>` (an Android emulator, a physical
device, `chrome`) — the same suite ran against a real Android 14 device
in Phase 10's native-widget verification setup, unchanged here.

## Design notes

**Location**: `apps/mobile/integration_test/`, not the repo-root
`integration_test/` sketched in `docs/ARCHITECTURE.md`'s Phase 0 tree —
Flutter's `integration_test` tooling requires the directory to be a
sibling of the Flutter project's own `pubspec.yaml`. That tree was
explicitly marked a "seed document"; this is the corrected, working
placement.

**Chaos Mode as a test fixture, not just a demo toy**: `offline_cache_test.dart`
drives `ChaosModeController.setNetwork(NetworkCondition.offline)` directly
rather than requiring a human to kill the backend process for every run.
Chaos Mode (Phase 9) was originally built for manual failure-mode demos;
reusing it here for deterministic, instant, repeatable fault injection in
an automated suite is the same infrastructure earning a second job, not a
new one built for testing specifically.

**Clean state per test**: `IntegrationHarness.build()`
(`test_harness.dart`) signs out and clears the connectivity cache before
every test. Widget tests reset automatically between runs; integration
tests run against a device's *real* platform storage (real
SharedPreferences), which persists across test invocations exactly like
it does for a real user reopening the app — without this, a test run
right after a manual demo session would silently start from whatever
state that session left behind.

**Native widget verification**: `RecordingNativeWidgetService`
(`test_harness.dart`) is a fake implementing the same `NativeWidgetService`
interface the app depends on, recording every call instead of reaching a
platform channel. This proves the *wiring* — that a successful
dashboard/connectivity load actually calls `updatePlan`/`updateConnectivity`
with the right data — without needing to inspect an actual home screen,
which stays a manual, live check (already done for Android against a
physical device in Phase 10; see ADR-007).

**Not yet wired into CI**: running these requires a live Postgres +
backend, which `flutter-ci.yml` doesn't provision. Phase 14 adds
`integration.yml` once the backend's CI environment can stand up that
dependency; until then, this suite is run and verified locally, the same
way every other phase's live verification has been.
