# RoamPulse

**Your connectivity, before you need to ask.**

RoamPulse is a simulated international connectivity companion for
travellers, built as a technical portfolio project demonstrating
production-minded Flutter/Dart, Go, and AI-workflow engineering.

This is not a Holafly clone — it's an original product concept engineered to
exercise the same skills: modular Flutter architecture, BLoC, offline-first
caching, native platform integration, a Go/PostgreSQL backend, and a
constrained AI agent, all under test-first development and CI.

[![flutter-ci](https://github.com/damilare-d/roam_pulse/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/damilare-d/roam_pulse/actions/workflows/flutter-ci.yml)
[![backend-ci](https://github.com/damilare-d/roam_pulse/actions/workflows/backend-ci.yml/badge.svg)](https://github.com/damilare-d/roam_pulse/actions/workflows/backend-ci.yml)
[![tools-ai-ci](https://github.com/damilare-d/roam_pulse/actions/workflows/tools-ai-ci.yml/badge.svg)](https://github.com/damilare-d/roam_pulse/actions/workflows/tools-ai-ci.yml)
[![integration](https://github.com/damilare-d/roam_pulse/actions/workflows/integration.yml/badge.svg)](https://github.com/damilare-d/roam_pulse/actions/workflows/integration.yml)

See [`docs/PRODUCT_DISCOVERY.md`](docs/PRODUCT_DISCOVERY.md) for the product
brief, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the technical
design, and [`docs/HOLAFLY_ROLE_MAPPING.md`](docs/HOLAFLY_ROLE_MAPPING.md)
for how each requirement maps to a concrete, tested feature — that document
is the fullest picture of what's built, what's tested, and what's honestly
still incomplete.

## Status

All 15 phases of the build plan are complete, ending with this README and
a full documentation consistency pass. Phases 0–14: product discovery, the
Flutter/BLoC dashboard, a Go/PostgreSQL backend, offline-first caching,
native Android (live-verified on a physical device) and iOS (written,
honestly unverified — no Mac available) home-screen widgets, a
developer-only Chaos Mode failure-simulation console, a deterministic
diagnostic engine with a Claude-backed recovery agent on top of it, an
AI-assisted engineering workflow gate-runner, a 5-scenario integration test
suite, and four green CI workflows. Full detail and status per requirement:
`docs/HOLAFLY_ROLE_MAPPING.md`.

**Known gaps, stated plainly**: `packages/analytics` (observability —
latency, cache hit/miss, sync duration, AI outcome logging) is still the
original Phase 1 scaffold, never implemented; there's no dedicated
`SyncBloc` or sync endpoint — the `sync_metadata` table exists in the
schema but nothing ever writes to it, since the network-first-with-cache
pattern that *was* built (ADR-006) covers the same need without it; the
iOS widget is written but unverified; the AI recovery agent's
genuine-Claude path is unit-tested against a fake client but not yet
demoed live (no `ANTHROPIC_API_KEY` provisioned). None of these are
hidden in the role-mapping table — they're marked 🔲/🟡 there, not quietly
left off this list.

## Feature tour

- **Dashboard**: trip, connectivity, usage, and plan data loaded in
  parallel from the real backend, each section an independent failure
  domain — a broken plan fetch never hides a working, cached connectivity
  card.
- **Offline-first caching**: network-first with a cache fallback; stale
  cached data is always visibly marked as such, never presented as fresh.
- **Native home-screen widgets**: Android (Jetpack Glance, live-verified)
  and iOS (WidgetKit, written) mirror the dashboard's connectivity and plan
  data without the Flutter engine running.
- **Chaos Mode**: a `kDebugMode`-gated developer console that deterministically
  simulates offline/timeout/slow-network/500/malformed-response conditions
  and cache expiry — every failure mode is reproducible on demand rather
  than relying on flaky real-world conditions to demo resilience.
- **Deterministic diagnostics + Claude recovery agent**: a pure, fully
  unit-tested rule engine determines the likely connectivity issue; an
  optional Claude-backed agent (backend-mediated only) turns that into a
  traveller-friendly recommendation, falling back to the deterministic
  answer — honestly labelled as a fallback — whenever Claude is
  unreachable or unconfigured.
- **AI-assisted engineering workflow**: `tools/ai/cmd/aiworkflow` runs
  format/analyze/test/coverage and refuses a "ready for review" verdict
  if any gate never ran or was skipped, with an explicit human-review
  confirmation gate that can't be granted automatically.
- **Integration test suite**: 5 real `integration_test` scenarios drive
  the actual app against the actual running backend — no mocks — wired
  into CI against a real, ephemeral Postgres instance.

## Repository structure

```text
roampulse/
├── apps/mobile/                   # Flutter application shell
│   └── integration_test/          # End-to-end scenarios (Phase 13)
├── packages/                      # Modular Flutter packages (see docs/ARCHITECTURE.md)
├── backend/api/                   # Go REST API, PostgreSQL, migrations
├── tools/ai/                      # AI-assisted development workflow (Phase 12)
├── docs/                          # Product, architecture, and decision docs
│   └── decisions/                 # ADRs
├── .github/workflows/             # flutter-ci, backend-ci, tools-ai-ci, integration
├── melos.yaml
└── pubspec.yaml                   # Dart pub workspace root
```

## Local setup

Requires Flutter (stable channel, 3.35.x), Go 1.24+, and PostgreSQL 16.

### 1. Database

```bash
psql -U postgres -c "CREATE ROLE roampulse WITH LOGIN PASSWORD 'roampulse';"
psql -U postgres -c "CREATE DATABASE roampulse_dev OWNER roampulse;"
```

### 2. Backend

```bash
cd backend/api
cp .env.example .env   # defaults already match the database created above

go run ./cmd/seed      # migrates, then loads deterministic demo data
go run ./cmd/api       # listens on :8080
curl http://localhost:8080/health
```

`ANTHROPIC_API_KEY` in `.env` is optional — leave it blank and the
Connectivity Recovery Agent (see ADR-008) falls back to the deterministic
diagnosis's own recommendation, honestly labelled as a fallback in the UI.

### 3. Flutter app

```bash
flutter pub get                 # resolves the whole workspace — app + every package
(cd apps/mobile && flutter run) # pick any connected device/target
```

An Android emulator reaches the backend via the built-in `10.0.2.2` alias
automatically. A physical device on the same LAN needs
`--dart-define=BACKEND_HOST=<your-machine's-LAN-IP>`.

### 4. Tests

```bash
# Formatting + static analysis, whole workspace
dart format --set-exit-if-changed .
dart analyze --fatal-infos

# Unit tests — pure Dart packages
dart test packages/core packages/network packages/analytics

# Unit/widget tests — Flutter-dependent packages + the app
for pkg in design_system storage connectivity plans diagnostics ai_agent; do
  (cd packages/$pkg && flutter test)
done
(cd apps/mobile && flutter test)

# Backend
(cd backend/api && go test ./...)

# Integration tests — needs the backend running (step 2) and a connected
# device/desktop target; swap -d windows for whatever `flutter devices` lists
# on your machine (this project's own dev environment is Windows)
(cd apps/mobile && for f in integration_test/*_test.dart; do flutter test "$f" -d windows; done)
```

Or run the whole mechanical gate sequence in one shot with the
AI-assisted-workflow tool itself (`docs/AI_DEVELOPMENT_WORKFLOW.md`):

```bash
cd tools/ai && go run ./cmd/aiworkflow --reviewer "your name, what you checked"
```

## Documentation map

| Doc | Covers |
|---|---|
| `docs/PRODUCT_DISCOVERY.md` | Problem, user, journey, MVP scope |
| `docs/ARCHITECTURE.md` | System design, package boundaries, data flow |
| `docs/HOLAFLY_ROLE_MAPPING.md` | Every requirement → implementation → tests → status |
| `docs/INTEGRATION_TESTING.md` | The 5 end-to-end scenarios, how to run them, design notes |
| `docs/CI_CD.md` | The four GitHub Actions workflows |
| `docs/AI_DEVELOPMENT_WORKFLOW.md` | The proposal→validate→generate→format→analyze→test→coverage→review pipeline |
| `docs/decisions/ADR-*.md` | Ten architecture decision records |
