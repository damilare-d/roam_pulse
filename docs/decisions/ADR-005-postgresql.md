# ADR-005: PostgreSQL with pgx, embedded migrations, CHECK-constraint enums

## Context

RoamPulse needs a relational store for travellers, plans, connectivity
events, and diagnostics — a naturally relational domain (foreign keys
between destinations/networks/plans/sessions) with no requirement for
horizontal scale, documents, or graph queries.

## Decision

- **PostgreSQL** as the only datastore. No Redis/cache layer at this stage
  (§47 — no infrastructure without a concrete requirement); connection
  pooling is handled in-process by `pgxpool`.
- **`jackc/pgx/v5`** as the driver, used directly (not through
  `database/sql`) for the application's own queries — pgx's native API is
  faster and more idiomatic than `database/sql` + a compatibility shim for
  a Postgres-only backend with no plans to support another database engine.
- **`golang-migrate/v4`** for schema migrations, with SQL files embedded
  into the binary via `go:embed` (`internal/postgres/migrations/*.sql`) —
  the server never depends on a migrations directory existing on disk at
  deploy time. The migration *driver* golang-migrate uses is its standard
  `database/postgres` package running over `pgx/v5/stdlib` (a
  `database/sql`-compatible shim) — only for migrations, where
  golang-migrate's own driver interface expects `database/sql`, not for
  the application's runtime queries.
- **CHECK constraints instead of native Postgres ENUM types** for
  status/state/category columns (plan status, connectivity state, signal
  strength, etc.). Adding a new allowed value is an `ALTER TABLE ...
  CHECK` migration either way, but CHECK constraints avoid `ALTER TYPE ...
  ADD VALUE`'s transaction restrictions and are simpler to reason about
  from application code, which mirrors the same value sets as Go string
  constants (`domain.ConnectivityState` etc.).
- Demo mode's single-active-trip assumption is enforced at the database
  level with a partial unique index
  (`CREATE UNIQUE INDEX ... ON travel_plans(traveller_id) WHERE status =
  'active'`) rather than only in application code, so it can't be violated
  by a bug in a future write path.

## Alternatives considered

- **MongoDB / a document store**: rejected — the domain is relational by
  nature (plans belong to travellers belong to destinations; sessions and
  events belong to plans); modeling it as documents would mean
  reimplementing joins in application code for no benefit.
- **`database/sql` + `lib/pq`** for application queries: rejected — `pgx`
  natively is the current idiomatic choice for Postgres-only Go backends
  and avoids the extra abstraction layer `database/sql` adds when nothing
  needs driver portability.
- **Raw SQL scripts run by hand / an ORM's auto-migrate**: rejected per
  §34 — manual schema changes aren't reproducible, and auto-migrate tools
  hide what's actually being applied to the database.

## Trade-offs

- Running the pgx/v5 driver twice (native `pgxpool` for the app,
  `pgx/v5/stdlib` + `database/sql` for golang-migrate) is slightly more
  than one dependency edge, but each is doing a job the other doesn't
  overlap with — golang-migrate doesn't support pgx's native interface
  directly.
- CHECK constraints must be kept in sync with the Go-side constants by
  hand; there's no single source of truth. Acceptable at RoamPulse's
  schema size.

## Consequences

- `postgres.Migrate()` and `postgres.Connect()` are called from both
  `cmd/api` and `cmd/seed`, so both entrypoints self-migrate — there is no
  separate "run migrations" step to forget in local dev.
- `postgres.Seed()` truncates and repopulates deterministic demo data
  (fixed UUIDs) — see docs/PRODUCT_DISCOVERY.md section 35 — so demo runs
  and screenshots are reproducible.
