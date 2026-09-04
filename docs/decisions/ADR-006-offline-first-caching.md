# ADR-006: Offline-first caching — network-first with cache fallback

## Context

docs/PRODUCT_DISCOVERY.md principle 4 says offline is a first-class state,
not an error; principle 2 says never let cached data look like fresh data.
Phase 6 needed to make at least one repository genuinely offline-first,
end to end, rather than describing the pattern only in a diagram.

**A naming clarification worth stating explicitly**: "offline" in this ADR
means *this Flutter app can't reach the RoamPulse backend* — a property of
the demo device's own network. That is a different concept from
`ConnectivityState.offline`, which describes the *simulated traveller's*
carrier connectivity within the product fiction (seeded/Chaos-Mode data
about their phone's signal in Japan). The two are unrelated and can vary
independently; conflating them would be a real correctness bug, not just
a naming nitpick.

## Decision

- **`Cached<T>`** (`packages/core`): a value plus `syncedAt` and `isStale`.
  Every connectivity repository method returns `Result<Cached<T>>`, not a
  bare `T` — even a same-instant network hit is wrapped
  (`isStale: false`) — so no code path can accidentally treat a value as
  unconditionally fresh.
- **`Cache<T>`** (`packages/storage`): one TTL-aware slot on top of
  `KeyValueStore` — JSON-serializes a value with a `syncedAt` timestamp,
  computes `isStale` on read by comparing against an injectable clock
  (`DateTime Function()`, defaulting to `DateTime.now`) so tests are
  deterministic without real delays.
- **`CachingConnectivityRepository`** (`packages/connectivity`): decorates
  `HttpConnectivityRepository` with **network-first, cache-fallback**:
  try the network; on success, write the cache and return fresh; on
  failure, read the cache and return it (stale) if present, otherwise
  propagate the original failure.
- **UI**: `ConnectivityBlocLoaded` carries `syncedAt`/`isStale`;
  `ConnectivityCard` renders a visibly different, warning-toned banner
  ("Showing saved data from X ago — no connection") only when stale, plus
  a manual refresh action — never silently swapping in old data.
- **Independent failure per card**: `DashboardPage` renders the profile
  card and `ConnectivityCard` as siblings, each owning its own bloc and
  failure state, rather than nesting one inside the other's loaded state.
  A failed profile fetch (uncached, out of this phase's scope) must not
  hide a working cached connectivity section behind a full-page error —
  discovered live while testing this ADR's own behavior, not designed in
  up front.

## Alternatives considered

- **True stale-while-revalidate** (serve cache immediately, refresh in
  the background, emit twice): the more complete interpretation of "SWR"
  and the more advanced pattern. Deliberately not built — it needs a
  stream-based repository API (`Stream<Result<Cached<T>>>` yielding
  cached-then-fresh) and a bloc that can emit twice per request, which is
  real added complexity for a demo app with one traveller and no organic
  offline flakiness beyond what Chaos Mode (Phase 9) will simulate
  on-demand anyway. Network-first-with-fallback gets the product
  requirement (works offline, never lies about freshness) with
  substantially less machinery. Named accurately in code as "network-first
  with cache fallback," not mislabeled as SWR.
- **Caching status and events as one combined blob**: rejected — they're
  distinct REST resources with potentially different staleness profiles
  (signal/latency could go stale faster than a rarely-changing event
  log); two `Cache<T>` instances keeps that correct.
- **Silently serving stale data with no visual indicator**: rejected
  outright — directly contradicts docs/PRODUCT_DISCOVERY.md principle 2.

## Trade-offs

- TTL-based staleness (5 minutes, configurable) is a blunt instrument —
  it doesn't know whether the underlying data has actually changed, only
  how long it's been since the last fetch. Acceptable for a demo app;
  revisit if a real product needed push-based invalidation.
- Only `ConnectivityRepository` is offline-first so far. `ProfileRepository`
  and future repositories adopt the same `Cache<T>`/`Cached<T>` pattern
  as they're built — this ADR establishes the pattern, not a claim that
  every repository already uses it.

## Consequences

- Verified live, not just unit-tested: primed the cache with a real
  backend round trip, killed the backend, relaunched the app — the
  connectivity card showed the last-known SoftBank/5G data with the stale
  banner instead of an error; restarting the backend and tapping refresh
  cleared the banner and returned fresh data.
- 21 new tests: `Cache<T>` TTL/staleness/overwrite/clear behavior,
  `CachingConnectivityRepository`'s three-way branch (fresh / stale
  fallback / no cache to fall back on), and the `ConnectivityCard`
  stale-banner rendering.
