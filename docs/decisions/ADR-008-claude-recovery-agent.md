# ADR-008: Claude-backed Connectivity Recovery Agent

## Context

Phase 11 adds the AI half ADR-009 deliberately deferred: a Claude-backed
recommendation that turns the deterministic diagnosis into a
traveler-friendly answer with concrete recovery steps. The build brief's
core constraint is explicit: **Claude is backend-mediated only, never
client-side** — no API key, prompt, or model call may live in the Flutter
app. A second, self-imposed constraint follows from ADR-009's own
premise: since the deterministic engine already exists specifically to be
a real fallback, the AI path must actually use it as one, not just cite it
in a comment.

## Decision

`AIRecoveryService` (`backend/api/internal/service/ai_recovery_service.go`)
is the only thing in RoamPulse that holds a Claude client. It:

1. Calls `DiagnosticService.Diagnose` (extracted from `RunDiagnostics` in
   this phase) to gather the same deterministic diagnosis Phase 8 already
   produces — no separate "AI gathering" path to keep in sync.
2. Persists that deterministic result first, under a **new**
   `diagnostic_sessions` row, exactly like `RunDiagnostics` does for the
   plain "Run diagnostics" button.
3. Sends it to Claude via `ClaudeClient.Recommend`, forcing a tool call
   (`tool_choice: {"type": "tool", "name": "provide_recovery_recommendation"}`)
   so the response is structured JSON, not prose to parse — `strict: true`
   on the tool schema makes the API itself guarantee valid types;
   `validateRecommendationPayload` checks the value *ranges* schema
   validation can't (1–4 non-empty steps, confidence in [0,1]).
4. On **any** failure past that point — network error, non-2xx, no
   `tool_use` block, or a payload that fails validation — falls back to
   the deterministic diagnosis's own recommendation, wrapped to the same
   `AIRecommendation` shape with `Source: "fallback"`. This is not an edge
   case bolted on; it's the reason ADR-009's engine is pure and
   independently correct in the first place.
5. A successful AI result is persisted as a **second** result row on the
   same session, tagged `domain.DiagnosticEngineAI` — the schema
   (`diagnostic_results.session_id` is 1-to-many) already supported this
   from Phase 8 without a migration.

`packages/ai_agent` (Flutter) mirrors `packages/diagnostics`'s shape
exactly: a domain model (`AiRecommendation`, with an `isFallback` getter),
a repository (`HttpAiRecoveryRepository` → `POST
/api/v1/diagnostics/recommend`), and an independent bloc
(`AiRecoveryBloc`). It is a second, separate bloc from `DiagnosticsBloc`
rather than a mode of it — "run the deterministic check" and "ask Claude"
are two distinct, separately user-triggered actions on the diagnostics
page, and the backend endpoint reruns its own deterministic pass anyway,
so the two blocs never need to share a `Diagnosis` value.

The UI always renders `AiRecommendation.source` — a fallback answer is
labelled "Fallback (AI unavailable)", never presented as if Claude
produced it. This is the same honesty ADR-006 already requires for stale
cached data: a degraded answer shown as if it were the real thing is
worse than an honestly-labelled degraded one.

**Model**: `claude-opus-5` — Anthropic's current default recommendation,
kept rather than downgraded to a cheaper tier on cost grounds alone (that
tradeoff belongs to whoever operates this in production, not to the code).
It's a single named constant (`claudeModel` in `claude_client.go`), so
changing it later is a one-line edit, not a design change.

**No API key required to run RoamPulse.** `ANTHROPIC_API_KEY` is an
optional config value (`internal/config/config.go`); when unset,
`ClaudeClient.Recommend` returns `ErrAIClientNotConfigured` immediately —
handled by `AIRecoveryService` exactly like every other AI failure mode
(fall back, log, don't error the request). An unprovisioned key is a
normal, expected state, not a startup failure.

## Alternatives considered

- **Client-side Claude calls** (Flutter → Anthropic directly): rejected
  outright — the build brief's own constraint, and it would put the API
  key in a shipped binary.
- **Free-form text generation, parsed with string matching**: rejected —
  forced tool use with `strict: true` gets structurally-valid JSON back
  from the API itself; parsing prose for "here are the steps: ..." is
  exactly the kind of brittle, un-testable I/O the pure-core/thin-shell
  pattern (ADR-009, Chaos Mode's `decideChaosAction`) exists to avoid.
- **Passing the caller's already-computed `Diagnosis` into the
  recommend endpoint** instead of re-running `Diagnose` server-side:
  rejected for this phase — it would require threading a diagnosis
  identity between two independent blocs/endpoints for a benefit that
  doesn't exist yet, since RoamPulse's simulated backend makes repeated
  `Diagnose` calls idempotent in practice. Worth revisiting if the
  backend ever models diagnostic state that can change between two
  requests a few seconds apart.
- **Retrying a failed Claude call before falling back**: rejected — a
  naive client-side retry multiplies cost for a demo-scale feature and
  RoamPulse's fallback is already a good answer, not a degraded one;
  Anthropic's own SDK-level retry semantics weren't adopted since this is
  a deliberately raw `net/http` client (see below).
- **Anthropic's official Go SDK**: rejected in favor of raw `net/http` —
  the backend's only two external dependencies before this phase were
  `pgx` and `golang-migrate`, both deliberately minimal; this is a single
  call site with one forced tool, well within reach of `net/http` +
  `encoding/json` without adopting a broader SDK surface RoamPulse doesn't
  otherwise need.

## Consequences

- `DiagnosticService.Diagnose` is now the shared gathering primitive;
  `RunDiagnostics` (Phase 8's endpoint) is unchanged in behavior — it's a
  thin wrapper that also persists.
- `ClaudeClient` is a thin I/O shell (`claude_client.go`); all the actual
  logic — prompt construction (`buildRecoveryPrompt`), the tool schema
  (`recoveryTool`), response validation (`validateRecommendationPayload`),
  and the fallback wrapper (`fallbackRecommendation`) — is pure and
  unit-tested without any network access. `ClaudeClient.Recommend` itself
  is tested against an `httptest.Server`, covering a valid `tool_use`
  response, a non-200 status, and a missing tool_use block.
- Verified without a live Claude API key (none provisioned yet): every
  fallback path (`AIClient` error, malformed payload) is covered by
  `ai_recovery_service_test.go` with a fake `AIClient`, and the "no key
  configured" path is covered directly
  (`TestClaudeClient_NoAPIKeyReturnsNotConfiguredWithoutMakingARequest`).
  A genuine end-to-end Claude call is expected to be verified live once a
  key is provisioned — until then, RoamPulse behaves correctly and
  honestly with the AI half entirely absent, which is itself the point of
  this design.
