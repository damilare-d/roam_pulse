# Holafly Senior Flutter Developer — Requirement Mapping

Status: Phase 0. All rows are **planned** — none built yet. This table gets
a status update at the end of every phase (§50 Definition of Done requires
it), so it doubles as a live progress record and interview leave-behind.

Legend: 🔲 planned · 🟡 in progress · ✅ done (tests + docs included)

| Requirement | RoamPulse feature | Implementation | Tests | Demo evidence | Status |
|---|---|---|---|---|---|
| Product discovery | Problem framing, user journeys | `docs/PRODUCT_DISCOVERY.md` | — | This document set | ✅ (Phase 0) |
| Modular / monorepo architecture | `packages/*` workspace | Dart pub workspace + Melos | `flutter pub get`/`melos run analyze`/`melos run test` verified locally across all 9 packages | Repo tree walkthrough | 🟡 |
| Flutter architecture (clean layering) | Presentation → BLoC → UseCase → Repository → DataSource | Enforced per package | Layer-boundary lint/review | Code walkthrough | 🔲 |
| BLoC state management | `ConnectivityBloc`, `DashboardBloc`, `UsageBloc`, `PlanBloc`, `DiagnosticsBloc`, `SyncBloc` | `flutter_bloc`, explicit events/states | BLoC unit tests per bloc | Connectivity state demo | 🔲 |
| Advanced networking | Dio client with interceptors, retry, timeouts, error classification | `packages/network` | Unit tests per failure type | Chaos Mode network scenarios | 🔲 |
| Advanced caching / offline-first | Stale-while-revalidate repository | `packages/storage` + `packages/connectivity`/`plans` repos | Cache TTL/staleness/miss tests | Offline demo (§27 scenario 2/3) | 🔲 |
| Native Android integration | Home-screen App Widget | Android widget module + `NativeWidgetService` bridge | Dart payload tests + native transform tests | Home-screen widget demo | 🔲 |
| Native iOS integration | WidgetKit widget | iOS widget extension + same bridge | Same as above | Home-screen widget demo | 🔲 |
| High-performance UI | Parallel dashboard API loading, rebuild discipline | `DashboardBloc` concurrent fetch | Widget tests + before/after timing note | `docs/PERFORMANCE.md` | 🔲 |
| Unit / widget / integration testing | Full pyramid per §25–27 | Across all packages | — | CI test reports | 🔲 |
| Test-first development | Behaviour → tests → implementation sequence | Process, not a single artifact | Commit history shows tests before/with implementation | Diagnostics engine (Phase 8) as example | 🔲 |
| AI-powered product workflow | Connectivity Recovery Agent | `packages/ai_agent` + Go AI orchestration | Mocked-Claude tests, schema validation tests | AI diagnostic demo (§27 scenario 5) | 🔲 |
| AI-assisted engineering workflow | `/tools/ai` proposal → validate → generate → test pipeline | `tools/ai` scripts | Guardrail tests (AI can't skip analysis/tests) | `docs/AI_DEVELOPMENT_WORKFLOW.md` | 🔲 |
| CI/CD | Per-surface GitHub Actions | `flutter-ci.yml`, `backend-ci.yml` authored (steps verified manually); `integration.yml` added in Phase 14 once `integration_test/` exists | CI itself is the test | Green pipeline screenshot (pending first GitHub push) | 🟡 |
| Observability | Latency, sync duration, cache hit/miss, connectivity transitions, AI outcome logging | `packages/analytics` + backend structured logs | Log-emission unit tests | Dev console log sample | 🔲 |
| Error handling | `AppFailure` hierarchy, structured backend errors | `packages/core` + Go error envelope | Failure-mapping unit tests | Error-state widget demo | 🔲 |
| Technical documentation | ADRs, architecture docs, API docs | `docs/` | — | This document set | 🟡 |
| Architecture decisions | ADR-001..010 | `docs/decisions/` (ADR-003 monorepo, ADR-004 Go backend written; remaining 8 land with their phases) | — | ADR walkthrough | 🟡 |
| Long-term codebase health | Package ownership boundaries, lint discipline, no dead abstractions | Ongoing | Static analysis in CI | Codebase tour | 🔲 |
