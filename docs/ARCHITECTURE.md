# RoamPulse — Architecture

Started as a Phase 0 seed document; sections that grew large enough to
need their own space got a dedicated doc as each phase landed, rather
than the specific filenames originally sketched here — this file stays
the high-level map and cross-links out to each:

- Caching: ADR-006
- Native widgets: ADR-007
- The Connectivity Recovery Agent: ADR-008 (§9 below has the corrected
  diagram)
- Testing strategy: `docs/INTEGRATION_TESTING.md` (§10)
- CI/CD: `docs/CI_CD.md` (§11)
- The AI-assisted engineering workflow (a different "AI" topic from the
  recovery agent): `docs/AI_DEVELOPMENT_WORKFLOW.md`

## 1. Proposed repository structure

```text
roampulse/
├── apps/
│   └── mobile/                  # Flutter application shell (thin)
├── packages/
│   ├── core/                    # Failures, result types, env/config, logging
│   ├── design_system/           # Colors, typography, spacing, shared widgets
│   ├── network/                 # Dio client, interceptors, error classification
│   ├── storage/                 # Local persistence abstraction (cache, TTL)
│   ├── connectivity/            # Connectivity domain + ConnectivityBloc
│   ├── plans/                   # Plan/usage/destination domain + BLoCs
│   ├── diagnostics/             # Deterministic diagnostic engine
│   ├── ai_agent/                # Claude client contracts + response validation
│   └── analytics/               # Lightweight observability hooks
├── backend/
│   └── api/                     # Go REST API, PostgreSQL, migrations
├── tools/
│   └── ai/                      # AI-assisted dev workflow scripts
├── apps/mobile/integration_test/ # End-to-end scenarios (§27) — corrected
│                                 # from this diagram's original repo-root
│                                 # placement; Flutter's integration_test
│                                 # tooling requires it live inside the
│                                 # Flutter project (Phase 13)
├── docs/
│   └── decisions/                # ADRs
├── scripts/
├── melos.yaml
├── pubspec.yaml                 # Dart pub workspace root
└── README.md
```

Package boundaries are drawn by **ownership of a domain concept**, not by
layer-for-layer's-sake: `connectivity` owns the connectivity state machine
end-to-end (domain → bloc), it does not get split into
`connectivity_domain` + `connectivity_bloc` packages — that split would add
workspace overhead with no real decoupling benefit (§47).

`apps/mobile` stays thin: routing wiring, DI composition, and app shell only.
Feature logic lives in `packages/*` so it's independently testable.

## 2. System architecture

```mermaid
flowchart LR
    subgraph Mobile["Flutter App (apps/mobile)"]
        UI[Presentation / Widgets]
        BLoC[BLoCs]
        Repo[Repositories]
        Cache[(Local Storage)]
        Dio[Dio Network Client]
        Widget[NativeWidgetService]
    end

    subgraph Native["Platform"]
        AndroidWidget[Android App Widget]
        iOSWidget[iOS WidgetKit]
    end

    subgraph Backend["Go Backend"]
        API[REST API v1]
        Svc[Application Services]
        Dom[Domain Layer]
        RepoIf[Repository Interfaces]
        Infra[Infra / Postgres Driver]
        AIProxy[AI Agent Orchestration]
    end

    PG[(PostgreSQL)]
    Claude[Claude API]

    UI --> BLoC --> Repo
    Repo --> Cache
    Repo --> Dio --> API
    Repo --> Widget --> AndroidWidget
    Widget --> iOSWidget

    API --> Svc --> Dom --> RepoIf --> Infra --> PG
    Svc --> AIProxy --> Claude
```

## 3. Flutter layering

```mermaid
flowchart TB
    P[Presentation: Widgets] --> B[BLoC: Events/States]
    B --> U[Use Case / Application Logic]
    U --> R[Repository]
    R --> D1[Remote Data Source - Dio]
    R --> D2[Local Data Source - Cache]
```

Widgets never import Dio, never construct HTTP requests, and never contain
branching business logic beyond `BlocBuilder`/`BlocListener` state mapping.

## 4. Connectivity data flow

```mermaid
stateDiagram-v2
    [*] --> Unknown
    Unknown --> Connecting
    Connecting --> Connected
    Connecting --> Offline
    Connected --> Degraded
    Connected --> Offline
    Degraded --> Connected
    Degraded --> Offline
    Offline --> Synchronizing
    Synchronizing --> Connected
    Synchronizing --> Error
    Error --> Connecting
```

## 5. Offline synchronization

```mermaid
sequenceDiagram
    participant UI
    participant Bloc
    participant Repo as Repository
    participant Cache
    participant API

    UI->>Bloc: request dashboard
    Bloc->>Repo: getDashboard()
    Repo->>Cache: read cached snapshot
    Cache-->>Repo: cached data + timestamp
    Repo-->>Bloc: emit cached (stale=true if TTL expired)
    Repo->>API: fetch fresh (background)
    alt API succeeds
        API-->>Repo: fresh data
        Repo->>Cache: write + update timestamp
        Repo-->>Bloc: emit fresh (stale=false)
    else API fails
        Repo-->>Bloc: keep cached, mark offline
    end
    Bloc-->>UI: state with data + freshness + connectivity
```

## 6. Data model proposal (PostgreSQL)

```text
users(id, email, auth_provider, created_at)

traveller_profiles(id, user_id fk, display_name, home_country, created_at)

travel_plans(id, traveller_id fk, destination_id fk, esim_id fk,
             starts_at, expires_at, data_allowance_mb, status)

destinations(id, country_code, city, timezone)

networks(id, destination_id fk, carrier_name, technology, mcc, mnc)

esims(id, traveller_id fk, iccid_simulated, status, activated_at)

network_sessions(id, plan_id fk, network_id fk, connected_at,
                  disconnected_at, signal_strength, latency_ms)

usage_records(id, plan_id fk, recorded_at, category, bytes_used)

connectivity_events(id, plan_id fk, occurred_at, from_state, to_state, reason)

diagnostic_sessions(id, plan_id fk, started_at, completed_at, trigger)

diagnostic_results(id, session_id fk, engine, issue, confidence,
                    severity, recommendation, raw_payload jsonb)

sync_metadata(id, traveller_id fk, resource, last_synced_at, checksum)
```

`diagnostic_results.raw_payload` stores both the deterministic engine's
structured output and (when invoked) the validated AI agent output, tagged
by `engine` — this keeps the two auditable and comparable without separate
tables.

## 7. API proposal (versioned REST)

```text
GET    /health

GET    /api/v1/profile
GET    /api/v1/trips/current
GET    /api/v1/plans/current
GET    /api/v1/usage
GET    /api/v1/connectivity
GET    /api/v1/connectivity/events
GET    /api/v1/destinations/:id
GET    /api/v1/networks/:id

POST   /api/v1/diagnostics
POST   /api/v1/ai/connectivity-diagnosis
POST   /api/v1/sync
```

Responses share a consistent envelope:

```json
{ "data": { }, "meta": { "syncedAt": "..." } }
```

Errors share a consistent structure:

```json
{ "error": { "code": "NETWORK_UNAVAILABLE", "message": "...", "details": {} } }
```

Full request/response schemas land in `docs/API.md` (Phase 2) via OpenAPI.

## 8. Native widget strategy

```mermaid
flowchart LR
    Flutter[Flutter: ConnectivityBloc] --> Service[NativeWidgetService]
    Service --> Bridge[Platform Channel]
    Bridge --> AndroidStore[Android: SharedPreferences/DataStore]
    Bridge --> iOSStore[iOS: App Group UserDefaults]
    AndroidStore --> AndroidWidget[Glance/RemoteViews Widget]
    iOSStore --> iOSWidget[WidgetKit Timeline Provider]
```

`NativeWidgetService` is a Dart-facing abstraction; Flutter writes a small,
serializable `ConnectivityWidgetPayload` (state, network, data remaining,
expiry) through it. The native widget owns its own rendering — Flutter never
draws widget UI, and the widget must render from last-written storage even
if the Flutter app/engine isn't running. This boundary is unit-testable on
the Dart side (payload construction/serialization) and covered by native
tests for the storage→UI transform on each platform.

## 9. AI agent architecture

Implemented in Phase 11 — see ADR-008 for the full design and rationale.
The version below corrects this section's original Phase 0 sketch, which
had Claude itself calling a constrained tool set to gather data; what was
actually built gathers data first (reusing the deterministic engine's own
logic) and only ever asks Claude for one thing: a structured
recommendation grounded in a diagnosis it's already been handed.

```mermaid
flowchart TB
    Traveller[Traveller taps "Get AI recommendation"] --> Backend[Go: POST /api/v1/diagnostics/recommend]
    Backend --> Gather[DiagnosticService.Diagnose — same gathering logic as Phase 8]
    Gather --> Diagnosis[Deterministic Diagnosis]
    Diagnosis --> Persist1[Persisted as a deterministic diagnostic_results row]
    Diagnosis --> Prompt[buildRecoveryPrompt]
    Prompt --> Claude[ClaudeClient.Recommend — forced tool_use, claude-opus-5]
    Claude --> Validate[validateRecommendationPayload]
    Validate -->|valid| AIResult[AIRecommendation, Source: ai]
    Validate -->|invalid or Claude unreachable/unconfigured| Fallback[fallbackRecommendation wraps the deterministic Diagnosis, Source: fallback]
    AIResult --> Persist2[Persisted as a second, ai-tagged row on the same session]
    AIResult --> User[Returned to traveller — UI always shows Source]
    Fallback --> User
```

The Claude API key lives only in the Go backend's environment. The Flutter
app calls `POST /api/v1/diagnostics/recommend` like any other endpoint;
it never talks to Anthropic directly.

## 10. Testing strategy

- **Unit**: domain models, use cases, repositories, cache TTL/staleness,
  retry logic, diagnostic engine, sync logic, serializers, BLoC state
  transitions.
- **Widget**: connected/offline/degraded/loading/error/stale-indicator
  rendering, diagnostic result rendering, Chaos Mode controls.
- **Integration**: five real `integration_test` scenarios
  (`apps/mobile/integration_test/`) built directly off the primary user
  journey (§3 of `PRODUCT_DISCOVERY.md`), driving the actual app against
  the actual running backend — no mocks. Full detail, design rationale,
  and how to run them: `docs/INTEGRATION_TESTING.md` (Phase 13).
- Backend: Go table-driven tests per layer (handler, service, repository)
  plus migration/seed verification.
- The AI recovery agent's tests run against a **fake** `AIClient` — no
  live Claude API calls in CI or in the integration suite (see ADR-008).

## 11. CI/CD strategy

Five independent per-surface workflows so a backend-only or mobile-only
change doesn't wait on unrelated jobs. Full detail (why separate
workflows, why `integration.yml` runs Linux desktop under `xvfb` rather
than reusing the Windows target verified locally, `services:` vs.
provisioning Postgres another way): `docs/CI_CD.md` (Phase 14).
`deploy-web.yml` came later still, alongside the live deployment — see
`docs/DEPLOYMENT.md`.

```mermaid
flowchart LR
    PR[Pull Request / push to main] --> FlutterCI[flutter-ci.yml: format, analyze, unit+widget tests, coverage]
    PR --> BackendCI[backend-ci.yml: gofmt, vet, tests, build]
    PR --> ToolsAiCI[tools-ai-ci.yml: gofmt, vet, tests, build]
    PR --> IntegrationCI[integration.yml: Postgres service + real backend + 5 integration_test scenarios on Linux desktop]
    Push[Push to main, apps/mobile or packages] --> DeployWeb[deploy-web.yml: build Flutter web, deploy to Vercel]
    FlutterCI --> Merge
    BackendCI --> Merge
    ToolsAiCI --> Merge
    IntegrationCI --> Merge
    DeployWeb --> Live[Live demo]
```
