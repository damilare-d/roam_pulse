# ADR-009: Deterministic diagnostics before AI

## Context

RoamPulse's AI layer (Phase 11, docs/PRODUCT_DISCOVERY.md section 15) will
add a Claude-backed Connectivity Recovery Agent. The build brief is
explicit that "the AI should not be the only source of truth" — RoamPulse
needs to be able to tell a traveller what's wrong with their connection
even when Claude is unreachable, rate-limited, or simply not yet built
(as of this phase).

## Decision

Build and ship the deterministic diagnostic engine (`service.Diagnose`,
`backend/api/internal/service/diagnostics_engine.go`) *before* any AI
integration exists, as its own phase (8), well ahead of Phase 11. It is:

- **Pure and deterministic**: `Diagnose(DiagnosticInput) Diagnosis` takes
  no context, does no I/O, reads no clock — the exact same input always
  produces the exact same output. This is what makes it fully
  unit-testable (9 table-driven tests, written before the implementation)
  and is also what will let Phase 11 use it as AI's fallback without any
  surprises.
- **Rule-based over five concretely-observable inputs** (plan active,
  eSIM active, network registered, signal strength, latency) evaluated in
  priority order — matching docs/PRODUCT_DISCOVERY.md section 14's
  example exactly: earlier, healthier checks show as passed even when a
  later one is what's actually wrong.
- **Persisted through the same tables Phase 11's AI engine will share**:
  `diagnostic_sessions` + `diagnostic_results`, tagged by
  `domain.DiagnosticEngineKind` (`"deterministic"` today, `"ai"` once
  Phase 11 lands). Both engines' results live in the same auditable log
  from day one, rather than the AI engine needing a parallel logging path
  bolted on later.

## A course-correction worth recording

The build brief's illustrative input list included "lastSync" — the
original implementation modeled this as the latest connectivity event's
age, flagging a result "Data may be out of date" past a threshold. Live
testing against real seed data caught this immediately: a connection that
has been stably "connected" for two straight days with nothing going
wrong has an *old* event timestamp for a good reason (events only fire on
state transitions), not a stale one. The rule flagged RoamPulse's own
flagship healthy scenario (Tokyo/SoftBank) as "out of date" purely because
nothing had gone wrong recently — the exact opposite of what "everything
looks good" should mean. The rule was removed rather than patched around,
and `DiagnosticInput` shrank from 7 fields to 5. A real "is this diagnosis
based on fresh data" concern belongs to the caching layer (ADR-006), not
to this rule set.

## Alternatives considered

- **Building the AI agent first, deterministic engine as its "fallback"
  afterthought**: rejected — inverts the brief's own priority and risks
  the deterministic path being under-tested since nothing would depend on
  it directly during development.
- **A generic rules engine / DSL for the checks**: rejected per §47 — five
  ordered `switch` cases are simpler to read, test, and modify than a
  configurable rule language for a check list this size.
- **Confidence as a categorical High/Medium/Low label** (matching the
  brief's human-readable mock) instead of a 0–1 float: rejected — the
  `diagnostic_results.confidence` column (and the AI agent's own output
  shape in section 15) is a float; using the same representation for both
  engines is what makes them comparable in the same table. The UI buckets
  the float into a label for display, not the other way round.

## Consequences

- `DiagnosticService.RunDiagnostics` gathers plan/eSIM/session state from
  existing repositories, calls the pure engine, and persists the result —
  a persistence failure is logged but never denies the traveller a
  diagnosis they're actively waiting on.
- `packages/diagnostics` (Flutter) is a thin consumer: domain model,
  repository, and `DiagnosticsBloc` — no diagnostic logic lives
  client-side, so the deterministic/AI distinction stays entirely a
  backend concern.
- Verified live: primed real seed data, ran `POST /api/v1/diagnostics`,
  confirmed both the healthy ("Everything looks good") and
  network-unavailable paths, and confirmed the result rows land in
  `diagnostic_sessions`/`diagnostic_results`.
