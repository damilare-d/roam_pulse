# ADR-010: Demo authentication with a swap-ready AuthRepository boundary

## Context

RoamPulse needs travellers to get from app launch to the dashboard without
implementing real OAuth/JWT — explicitly out of scope for this phase per
the brief (§3, §47: "do not prematurely implement OAuth"). But the
boundary has to actually be ready for JWT/Google/Apple later, not just
described as ready.

## Decision

- **Backend**: `POST /api/v1/auth/demo` (`AuthService.SignInDemo`) verifies
  the seeded demo traveller exists and returns a fixed placeholder
  `sessionToken` (`"demo-session-token"`). It carries no real security
  meaning — nothing server-side currently checks it — but it makes the
  endpoint shape (`POST` credentials-ish input → session token out) the
  same shape a `POST /api/v1/auth/login` (JWT) or
  `POST /api/v1/auth/google` (OAuth) endpoint will have.
- **Flutter**: `AuthRepository` (interface) → `HttpAuthRepository`
  (implementation) is the conceptual boundary from §3 of the brief,
  literally implemented: `signInDemo()`, `hasActiveSession()`, `signOut()`.
  The session token is persisted through `packages/storage`'s
  `KeyValueStore` (its first real caller — see ADR from Phase 3's storage
  package). A future `JwtAuthRepository` implements the same three
  methods against real endpoints; nothing above the interface (the
  `AuthBloc`, `SplashPage`, `DemoEntryPage`, `AuthGuard`) needs to change.
- **Routing**: `SplashPage` checks `hasActiveSession()` once on launch and
  redirects to `DashboardRoute` or `DemoEntryRoute`. `AuthGuard` (an
  `auto_route` `AutoRouteGuard`) additionally protects `DashboardRoute`
  directly, so a deep link straight to the dashboard still redirects an
  unauthenticated user to the demo entry screen instead of rendering.

## Alternatives considered

- **Fully client-side demo entry (no backend call, just a local flag)**:
  rejected — it would make "authentication-ready architecture" a claim
  instead of a demonstrated pattern. Routing an actual network call
  through the same `Result<T>`/`AppFailure` path every other repository
  uses is what proves the boundary generalizes.
- **Implementing JWT now since the shape is so close**: rejected per
  §3/§47 — no real user accounts, password storage, or token refresh
  logic is justified for a demo-mode app with one seeded traveller.
- **A route guard alone, no splash check**: rejected — without the splash
  redirect, every fresh launch would flash the dashboard's guard-redirect
  logic before landing on demo entry; checking once at launch is both
  simpler and avoids that flash.

## Trade-offs

- The "session token" has zero cryptographic meaning today — it is
  intentionally inert, a placeholder for what Phase-N+1 JWT work makes
  real. Anyone reading the code should not mistake it for security.

## Consequences

- `TravellerProfile`'s current single-demo-traveller assumption
  (docs/PRODUCT_DISCOVERY.md) still holds — `signInDemo()` doesn't take
  or need credentials because there is exactly one traveller to sign in
  as.
- When real auth arrives, `HttpAuthRepository` is replaced/extended, not
  redesigned: `AuthBloc`, `SplashPage`, `DemoEntryPage`, and `AuthGuard`
  are all written against the `AuthRepository` interface, not against
  `HttpAuthRepository` directly.
