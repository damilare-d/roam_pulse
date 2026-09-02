# ADR-004: Go backend with stdlib routing

## Context

RoamPulse needs a REST API that: serves seeded demo data, proxies Claude
calls so the API key never reaches the Flutter client, and demonstrates a
clean, idiomatic service boundary independent of Flutter/Dart patterns.

## Decision

Use Go for the backend, structured as
`HTTP handlers → application/service layer → domain layer → repository
interfaces → infrastructure (Postgres)`. For routing, use the standard
library's `net/http.ServeMux` with Go 1.22+ method+pattern routing
(`mux.HandleFunc("GET /health", ...)`) rather than a third-party router —
Go's enhanced mux already gives method matching and path parameters, which
is all RoamPulse's route set needs.

## Alternatives considered

- **chi / gin / echo**: rejected for now — none of RoamPulse's routes need
  the extra features (complex middleware chains, route grouping at scale)
  that these add over the modern stdlib mux. Revisit only if a concrete
  routing need emerges (§47: no complexity without justification).
- **Node/Express or Python/FastAPI**: rejected — the brief specifically
  calls for a Go backend to demonstrate a statically-typed, concurrent
  service boundary distinct from the Flutter/Dart side.

## Trade-offs

- stdlib mux has a smaller feature set than chi/gin (no built-in middleware
  composition helpers) — acceptable at RoamPulse's route count; would be
  revisited if the route surface grows substantially.

## Consequences

- `backend/api` is a self-contained Go module (`roampulse/backend`),
  independent of the Dart workspace, with its own CI workflow
  (`backend-ci.yml`: gofmt, vet, build, test).
- Phase 1 ships only `GET /health`; the full `/api/v1/*` surface, the
  service/domain/repository layers, and PostgreSQL land in Phase 2.
