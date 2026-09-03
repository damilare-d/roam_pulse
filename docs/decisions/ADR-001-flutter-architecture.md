# ADR-001: Flutter layering — Presentation → BLoC → Repository → Data Source

## Context

RoamPulse's brief is explicit (§20): widgets must stay dumb, business logic
must not live in the UI, and widgets must not know about HTTP. Phase 3
needed to establish this pattern concretely — not just describe it — with
one real vertical slice before Phase 5+ builds the connectivity and plan
domains on top of it.

## Decision

Every feature follows:

```text
Presentation (widgets)
    ↓ reads/dispatches via BlocBuilder/BlocListener
BLoC (events in, states out)
    ↓ calls
Repository (interface)
    ↓ implemented by
Data source (ApiClient / KeyValueStore)
```

Established in `apps/mobile/lib/features/dashboard/` as the reference
implementation: `DashboardPage` → `DashboardBloc` → `ProfileRepository`
(interface, with `HttpProfileRepository` as the real implementation) →
`ApiClient`. Repositories are always interfaces, even when there's
currently only one implementation — this is what makes `DashboardBloc`
testable against a fake without a network call (see
`dashboard_bloc_test.dart`), and it's the seam Phase 6 hooks
stale-while-revalidate caching into without changing the BLoC or the UI.

Failures cross every one of these boundaries as a `Result<T>`
(`packages/core`), never a thrown exception — `ApiClient.getJson` returns
`Result<T>`, repositories return `Result<T>`, and the BLoC pattern-matches
it into a state. The UI never sees a raw `DioException` or catches
anything; `AppFailure.message` is already a string safe to show a
traveller.

## Alternatives considered

- **Repositories returning `Future<T>` and throwing on failure**: rejected
  — it pushes try/catch into the BLoC (or worse, the widget), and error
  classification becomes ad hoc per call site instead of centralized in
  `mapDioException`.
- **A dedicated use-case layer between BLoC and repository**: not added
  yet — for the endpoints Phase 3 covers, the BLoC's own event handler is
  the use case. Introduce a use-case class only when one repository call
  stops being enough (e.g. an action that touches two repositories and has
  its own validation) — TripService on the backend is already an example
  of that shape; the Flutter side gets it the first time a BLoC needs it,
  not preemptively.
- **A generic `Repository<T>` base class**: rejected — every repository's
  method names are domain-specific (`getProfile`, later `getCurrentTrip`,
  `getConnectivityStatus`); a shared generic base would either be empty or
  force an unnatural common shape onto unrelated domains.

## Trade-offs

- One interface per repository means one extra file per feature, even
  when (as today) there's only one implementation. Accepted for
  testability — see `dashboard_bloc_test.dart` and
  `dashboard_page_test.dart`, both of which run with zero network access.

## Consequences

- `TravellerProfile` and `ProfileRepository` currently live inside
  `apps/mobile/lib/features/dashboard/` rather than a `packages/plans`
  domain package — intentional Phase 3 scoping (see the doc comment on
  `TravellerProfile`). They move into `packages/plans` in Phase 7 once the
  full traveller/plan/usage domain is built there; the interface stays the
  same, only its location changes.
