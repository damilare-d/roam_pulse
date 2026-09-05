# CI/CD strategy

Four independent GitHub Actions workflows, each scoped to the part of the
repo it actually needs to check — a mobile-only change doesn't wait on a
Postgres-backed integration run, and a docs-only change doesn't trigger
any of them.

| Workflow | Runs on | What it checks |
|---|---|---|
| `flutter-ci.yml` | `ubuntu-latest` | `dart format`, `dart analyze --fatal-infos`, unit/widget tests across every Dart package + `apps/mobile`, coverage upload |
| `backend-ci.yml` | `ubuntu-latest` | `gofmt`, `go vet`, `go build`, `go test` for `backend/api` |
| `tools-ai-ci.yml` | `ubuntu-latest` | Same four checks, for `tools/ai` — its own Go module (Phase 12) |
| `integration.yml` | `ubuntu-latest` | The 5 real `integration_test` scenarios (Phase 13) against a real Postgres + backend |

`flutter-ci.yml` and `backend-ci.yml` predate this document (Phase 3/4);
`tools-ai-ci.yml` and `integration.yml` are this phase's additions —
`docs/AI_DEVELOPMENT_WORKFLOW.md` and `docs/INTEGRATION_TESTING.md` cover
those two features' own design; this document covers only the CI wiring.

## `integration.yml`

The one workflow that's more than "run a formatter/analyzer/test binary":

1. **Postgres via a service container.** `services: postgres: image:
   postgres:16` — GitHub's native way to give a Linux-runner job a
   throwaway database reachable at `localhost:5432`, no Docker Compose or
   manual container management needed. Neither `flutter-ci.yml` nor
   `backend-ci.yml` needs this — their Go tests already run against fakes
   (`fakeDiagnosticRepo` and friends), never a real database.
2. **Migrate + seed, then start the backend in the background.**
   `go run ./cmd/seed` (migrates, then seeds deterministic demo data —
   the exact command a developer runs locally, see `backend/api/cmd/seed`),
   then `go run ./cmd/api &`, then poll `GET /health` until it responds
   before running anything against it. A backend that isn't actually
   ready yet would otherwise fail every scenario with a connection error
   that looks like a real bug.
3. **Linux desktop, not the Windows target verified locally.** Every
   integration scenario in Phase 13 was hand-verified on `-d windows`,
   since that's this project's development environment. GitHub-hosted
   Windows runners exist, but don't support the `services:` Postgres
   container GitHub only offers on Linux runners — provisioning Postgres
   on Windows would mean Chocolatey or a Windows-specific action instead,
   a second kind of database setup alongside the Linux-native one every
   other workflow already uses. Linux desktop keeps all four workflows on
   the same runner OS and the same Postgres mechanism; `apps/mobile/linux/`
   already existed as a complete, if previously unused, Flutter-generated
   scaffold, so no new platform target had to be created; only the CI
   environment for it is genuinely new and unverified until this workflow
   actually runs.
4. **`xvfb-run`.** A Linux *desktop* Flutter app is a real windowed GTK
   application, even under `flutter test`, and GitHub's Ubuntu runners
   have no display server. `xvfb-run -a` gives it a virtual one.
5. **One `flutter test` invocation per scenario file**, not a single
   `flutter test integration_test/`, so a failure in one scenario doesn't
   abort the rest and the log clearly attributes failures to a specific
   journey step (each wrapped in a `::group::` for readability).
6. **Backend log always uploaded** (`if: always()`), so a failure whose
   cause is on the backend side — not the Flutter side — is diagnosable
   from the workflow run without needing to reproduce it locally.

## Consequences

- Passed on the first push: `integration-test` completed in 4m18s,
  Postgres/migrate/seed/backend-health-check/all 5 Linux-desktop-under-`xvfb`
  scenarios green with no iteration needed
  (github.com/damilare-d/roam_pulse/actions/runs/33968772257). The design
  reasoning above (mirror what's verified locally, add the smallest new
  surface needed) held up against a genuinely new, previously-unrehearsed
  CI environment.
- If Linux desktop under `xvfb` ever turns out not to work reliably (a
  future Flutter/Ubuntu version drift, say), the fallback is
  `-d web-server` (an embedded headless Chrome-based target
  `integration_test` also supports) — noted here rather than built
  pre-emptively, since building a second, unverified fallback path before
  the first one had even run once would have been exactly the kind of
  untested complexity this project avoids elsewhere.
