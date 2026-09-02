# ADR-003: Monorepo with Dart pub workspaces + Melos

## Context

RoamPulse has multiple independently-testable Flutter domains (connectivity,
plans, diagnostics, ai_agent, storage, design_system, analytics, core) plus
a Go backend, sharing one product and one release cadence during a
portfolio build.

## Decision

Use a single repository. Flutter packages are resolved with Dart's native
pub workspaces (`workspace:` in the root `pubspec.yaml`, `resolution:
workspace` in each member) so a single `flutter pub get` at the root
resolves every package into one shared lockfile. Melos sits on top for
cross-package orchestration scripts (`melos run analyze`, `melos run test`)
rather than for dependency resolution itself, since native workspaces now
handle that natively as of Dart 3.6+.

The Go backend (`backend/api`) is its own Go module inside the same
repository — Go modules and Dart workspaces don't share tooling, so it is
orchestrated separately (its own CI workflow, its own `go.mod`).

## Alternatives considered

- **Separate repositories per package**: rejected — for a single-engineer
  portfolio project this adds versioning/publishing overhead (private pub
  server or path overrides across repos) with no team-boundary benefit to
  justify it.
- **Melos-only resolution (pre-native-workspace style, `melos bootstrap`
  generating `pubspec_overrides.yaml` per package)**: still available as a
  fallback, but native pub workspaces are the current recommended approach
  for a repo this size and avoid an extra generated-file layer.
- **Single Flutter package, no `packages/*` split**: rejected — it would
  make "modular architecture" and "package ownership boundaries" invisible
  in the codebase, which is one of the things this project exists to
  demonstrate (§19, §48 of the build brief).

## Trade-offs

- Pub workspaces are a newer feature; less prior art/tooling documentation
  than the classic Melos-bootstrap approach.
- Two separate build systems (Dart workspace + Go module) in one repo means
  two separate CI workflows rather than one unified pipeline.

## Consequences

- `flutter pub get` at the repo root is the single source of truth for
  Flutter dependency resolution; running it inside a package directory also
  works and resolves against the same root lockfile (verified in Phase 1).
- Package boundaries must be justified by real ownership, not created
  speculatively — enforced by review, not tooling.
