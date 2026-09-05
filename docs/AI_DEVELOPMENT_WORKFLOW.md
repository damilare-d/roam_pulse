# AI-assisted engineering workflow

RoamPulse itself was built through the exact process this document
describes — every phase in `docs/HOLAFLY_ROLE_MAPPING.md` followed this
same eight-stage shape, with Claude Code acting as the developer and a
human approving scope at each phase gate. This document names the
process explicitly and `tools/ai/` enforces the half of it that must
never be skippable, regardless of who — or what — wrote the code.

## The eight stages

1. **Proposal** — a feature or fix is scoped in plain language before any
   code is written. In this project, that was a phase description from
   the build brief (e.g. "Phase 9: developer-only failure simulation");
   in day-to-day use, it's whatever a developer asks Claude to build.
2. **Architecture validation** — the proposal is checked against
   `docs/decisions/*.md` and the package boundaries in
   `docs/ARCHITECTURE.md` *before* generation starts. Concretely, this
   project's own ADRs are the validation record: ADR-006 ruled out
   full stale-while-revalidate caching before `CachingConnectivityRepository`
   was written; ADR-009 committed to a pure, deterministic diagnostic
   engine before any AI integration existed, specifically so Phase 11
   would have a real fallback instead of retrofitting one.
3. **Code generation** — Claude writes the implementation, following the
   validated approach. Genuinely AI-authored, not templated.
4. **Formatting** — `dart format --set-exit-if-changed .` /
   `gofmt`-equivalent (`go vet` catches most of what matters here in Go).
5. **Static analysis** — `dart analyze --fatal-infos`, `go vet ./...`.
6. **Tests** — the full suite for whatever the change touches: Go
   table-driven tests, Dart unit/bloc/widget tests. This project's own
   test-first pattern (ADR-009's diagnostic engine, Chaos Mode's
   `decideChaosAction`, the native widgets' `WidgetTransformTest.kt`, the
   AI recovery agent's `ai_recovery_test.go`) is stage 3 and stage 6
   interleaved: tests were often written *before* the implementation they
   verify.
7. **Coverage** — measured and reported, not gated on an invented
   percentage threshold the brief never specified. The point is that a
   reviewer can see it, not that a script silently waves changes through
   because a number cleared some arbitrary bar.
8. **Human review** — a person reads the diff and explicitly confirms it.
   No automation stands in for this step.

## What `tools/ai/` actually enforces

Stages 1–3 are a collaboration between a developer and Claude that
happens *before* this tool is ever invoked — they can't be mechanically
verified, and pretending otherwise would be exactly the kind of
fabricated automation this project avoids elsewhere (see ADR-009's
course-correction: a rule that looked plausible but was wrong was removed
rather than kept for appearances).

Stages 4–8 are what `tools/ai/cmd/aiworkflow` actually runs, every time,
in full:

```
cd tools/ai
go run ./cmd/aiworkflow --reviewer "Alex, reviewed the diff locally"
```

It runs formatting, static analysis, the entire test suite (Dart and Go,
mirroring `flutter-ci.yml`/`backend-ci.yml`'s own package split so a
Flutter-dependent package never gets run through plain `dart test` — the
exact bug this project hit twice, first with `packages/diagnostics` in
Phase 8 and again with `packages/ai_agent` in Phase 11), and coverage
instrumentation, then prints a `READY FOR REVIEW` or `NOT READY` verdict.

The verdict logic (`tools/ai/internal/pipeline`) is a pure function,
`Evaluate([]GateResult) Verdict`, deliberately separated from the `os/exec`
shell that runs the real commands — the same pure-core/thin-IO-shell split
as `ADR-009`'s diagnostic engine and Chaos Mode's `decideChaosAction`. That
split is what makes the actual guarantee — **a gate that never ran, or
was marked "skipped," blocks the verdict exactly like a failed one** — a
handful of table-driven unit tests instead of something only checkable by
running the whole real pipeline over and over.

The human-review gate is the sharpest edge of that guarantee:
`HumanReviewGate` has no code path that returns a passing result except a
non-empty, human-supplied `--reviewer` string. There's no flag, no
default, and no way for an AI-driven invocation to grant itself that gate.

## Consequences

- Every phase of RoamPulse's own build followed the proposal → validate →
  generate → test cycle before this tool existed to name and enforce the
  mechanical half of it — this document formalizes a practice already in
  use, not a new one.
- `tools/ai` is its own Go module (own `go.mod`), separate from
  `backend/api`, matching its role as developer tooling rather than
  shipped product code.
- No Anthropic API key is required to run `aiworkflow` — stages 1–3 stay
  a human/Claude collaboration outside the tool; see ADR-008 for the
  separate, in-product Connectivity Recovery Agent, which *does* call
  Claude, strictly from the backend.
