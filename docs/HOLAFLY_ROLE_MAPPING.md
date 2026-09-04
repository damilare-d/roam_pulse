# Holafly Senior Flutter Developer — Requirement Mapping

Status: living document, updated at the end of every phase (§50
Definition of Done requires it) — currently through Phase 5. Doubles as a
progress record and interview leave-behind.

Legend: 🔲 planned · 🟡 in progress · ✅ done (tests + docs included)

| Requirement | RoamPulse feature | Implementation | Tests | Demo evidence | Status |
|---|---|---|---|---|---|
| Product discovery | Problem framing, user journeys | `docs/PRODUCT_DISCOVERY.md` | — | This document set | ✅ (Phase 0) |
| Modular / monorepo architecture | `packages/*` workspace | Dart pub workspace + Melos; `core`, `network`, `design_system`, `storage`, `connectivity` now have real implementations, not just scaffolds | `flutter pub get`/`melos run analyze`/`melos run test` pass across all 9 packages + app | Repo tree walkthrough | 🟡 |
| Flutter architecture (clean layering) | Presentation → BLoC → Repository → DataSource | `DashboardPage`/`DemoEntryPage`/`ConnectivityCard` → Bloc → Repository → `ApiClient`; `AuthGuard` (`auto_route`) protects `DashboardRoute`, `SplashPage` does the one-shot launch check; `connectivity` is the first feature domain to live in its own package rather than app-local (see ADR-001, ADR-010) | `dashboard_bloc_test.dart`, `dashboard_page_test.dart`, `auth_bloc_test.dart`, `auth_repository_test.dart`, `demo_entry_page_test.dart`, `connectivity_bloc_test.dart`, `connectivity_test.dart`, `connectivity_card_test.dart` (all zero network access) | Live Windows desktop run: splash → demo entry → dashboard showing traveller + live connectivity card, all against the real backend | 🟡 |
| BLoC state management | `DashboardBloc` (Phase 3), `AuthBloc` (Phase 4), `ConnectivityBloc` (Phase 5) shipped; `UsageBloc`, `PlanBloc`, `DiagnosticsBloc`, `SyncBloc` remain | `flutter_bloc`, sealed event/state classes; see ADR-002 | 9 unit tests across `DashboardBloc`/`AuthBloc`/`ConnectivityBloc` (initial state, success path, failure path each) | Live demo: splash → entry → loading → dashboard with connectivity card | 🟡 |
| Advanced networking | Dio client with error classification mirroring backend `apperror` codes; timeouts configured; `postJson`/`getJsonList` added for POST and list endpoints | `packages/network` (`ApiClient`, `mapDioException`) | 6 unit tests covering timeout/connection/NOT_FOUND/VALIDATION_ERROR/fallback-by-status/unknown | Live HTTP round-trip (Dio log) against the Go backend, incl. parallel connectivity+events requests | 🟡 |
| Advanced caching / offline-first | Stale-while-revalidate repository | `packages/storage` (seam ready — `KeyValueStore`, first real caller is `HttpAuthRepository`'s session) + `packages/connectivity` repo | Cache TTL/staleness/miss tests | Offline demo (§27 scenario 2/3) | 🔲 (Phase 6) |
| Native Android integration | Home-screen App Widget | Android widget module + `NativeWidgetService` bridge | Dart payload tests + native transform tests | Home-screen widget demo | 🔲 |
| Native iOS integration | WidgetKit widget | iOS widget extension + same bridge | Same as above | Home-screen widget demo | 🔲 |
| High-performance UI | Parallel dashboard API loading, rebuild discipline | `ConnectivityBloc` fetches status + recent events concurrently (both futures started before either is awaited) rather than sequentially | `connectivity_bloc_test.dart` covers both-succeed and either-fails cases | Dio log shows both `/connectivity` and `/connectivity/events` requests firing before either resolves | 🟡 |
| Unit / widget / integration testing | Full pyramid per §25–27 | Across all packages | — | CI test reports | 🔲 |
| Test-first development | Behaviour → tests → implementation sequence | Process, not a single artifact | Commit history shows tests before/with implementation | Diagnostics engine (Phase 8) as example | 🔲 |
| AI-powered product workflow | Connectivity Recovery Agent | `packages/ai_agent` + Go AI orchestration | Mocked-Claude tests, schema validation tests | AI diagnostic demo (§27 scenario 5) | 🔲 |
| AI-assisted engineering workflow | `/tools/ai` proposal → validate → generate → test pipeline | `tools/ai` scripts | Guardrail tests (AI can't skip analysis/tests) | `docs/AI_DEVELOPMENT_WORKFLOW.md` | 🔲 |
| CI/CD | Per-surface GitHub Actions | `flutter-ci.yml`, `backend-ci.yml` live on GitHub; `integration.yml` added in Phase 14 once `integration_test/` exists | CI itself is the test | Both workflows green on `main` (github.com/damilare-d/roam_pulse/actions) | 🟡 |
| Observability | Latency, sync duration, cache hit/miss, connectivity transitions, AI outcome logging | `packages/analytics` + backend structured logs | Log-emission unit tests | Dev console log sample | 🔲 |
| Error handling | `AppFailure` hierarchy (Flutter) mirrors `apperror` codes (Go) | `packages/core` + `packages/network`'s `mapDioException` + Go error envelope | Failure-mapping unit tests both sides (Go `apperror_test.go`, Dart `network_test.dart`) | Error-state widget demo (`ErrorView` + retry) | 🟡 |
| Technical documentation | ADRs, architecture docs, API docs | `docs/` | — | This document set | 🟡 |
| Architecture decisions | ADR-001..010 | `docs/decisions/`: ADR-001 (Flutter layering), ADR-002 (BLoC), ADR-003 (monorepo), ADR-004 (Go backend), ADR-005 (PostgreSQL), ADR-010 (demo auth) written; remaining 4 land with their phases | — | ADR walkthrough | 🟡 |
| Long-term codebase health | Package ownership boundaries, lint discipline, no dead abstractions | Ongoing | Static analysis in CI | Codebase tour | 🔲 |
