# AI development workflow tooling

The mechanical half of RoamPulse's AI-assisted engineering workflow — see
`docs/AI_DEVELOPMENT_WORKFLOW.md` for the full eight-stage process this
implements the second half of (formatting → static analysis → tests →
coverage → human review; proposal → architecture validation → code
generation happen before this tool is ever invoked).

## Usage

```bash
cd tools/ai
go run ./cmd/aiworkflow --reviewer "your name, what you checked"
```

Without `--reviewer`, the human-review gate can't pass and the tool
prints `NOT READY` — there's no flag or default that grants it
automatically.

## Structure

- `internal/pipeline/` — pure gate-evaluation logic (`Evaluate`,
  `HumanReviewGate`), unit-tested without running any real tool.
- `cmd/aiworkflow/` — the thin shell that actually runs `dart format`,
  `dart analyze`, the full Dart/Go test suites (with coverage
  instrumentation), and prints the verdict.

Its own tests: `cd tools/ai && go test ./...`. CI: `tools-ai-ci.yml`.
