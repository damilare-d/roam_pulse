# RoamPulse — Product Discovery

Written in Phase 0 and unchanged since — the product foundation every later
engineering decision traces back to. See `docs/HOLAFLY_ROLE_MAPPING.md` for
what's actually been built against it.

## 1. User problem

International travellers lose confidence in their connectivity the moment
they leave their home network. The underlying anxiety is not "what is my
signal strength" — it is three unanswered questions:

1. **Am I connected right now?**
2. **How much connectivity do I have left, and until when?**
3. **If something is wrong, what do I do about it, and can I trust the answer?**

Existing eSIM/roaming apps mostly answer question 2 (a data-remaining
counter) and leave 1 and 3 to the OS status bar and generic troubleshooting
articles. RoamPulse is built specifically to answer all three, including
under degraded or offline conditions — which is exactly when the traveller
needs the app most and trusts it least.

## 2. Target user

A **leisure or business international traveller** using an eSIM/roaming data
plan, who:

- Is unfamiliar with the local carrier landscape.
- Has intermittent connectivity (transit, rural areas, hotel dead zones).
- Is not technical — "network registered: false" means nothing to them, but
  "Try turning Airplane Mode on and off" does.
- Wants reassurance more than raw telemetry. A calm, confident answer beats a
  dashboard full of numbers.

## 3. Primary user journey

```text
Open RoamPulse
    ↓
Enter demo mode
    ↓
See current trip
    ↓
See connectivity status
    ↓
See data remaining
    ↓
See plan expiry
    ↓
See network
    ↓
See usage
    ↓
Inspect connection quality
    ↓
Experience an outage
    ↓
RoamPulse detects degraded connectivity
    ↓
Application switches to cached/offline state
    ↓
User opens diagnostics
    ↓
Diagnostic engine determines likely issue
    ↓
AI agent can provide contextual guidance
    ↓
Network is restored
    ↓
Application synchronizes
    ↓
Native widget updates
```

This is the spine the integration test suite (Phase 13) is built around —
every step above becomes an assertable state transition.

### Secondary journeys

- **Glance journey**: user never opens the app, just checks the home-screen
  widget before deciding whether to use data-hungry apps.
- **Expiry journey**: plan is about to expire; user wants a clear, early,
  non-alarming warning (not a jump-scare red banner at 0%).
- **Developer/demo journey**: engineer or interviewer opens Chaos Mode to
  showcase resilience without needing a real network failure.

## 4. Pain points RoamPulse addresses

| Pain point | How RoamPulse responds |
|---|---|
| "Is this spinner because I'm offline, or just slow?" | Explicit connectivity states (`Connecting`, `Degraded`, `Offline`) instead of a binary loading flag. |
| "The app went blank when I lost signal." | Offline-first: last-known-good data stays visible, clearly labeled as cached. |
| "I don't know if it's my phone, my plan, or the carrier." | Deterministic diagnostic engine inspects plan/eSIM/network/signal independently and reports which one failed. |
| "Support articles are generic and don't know my situation." | AI recovery agent reasons over the traveller's actual structured diagnostic data, not a canned FAQ. |
| "I have to open the app just to check my data." | Native home-screen widget mirrors connectivity/data/expiry without launching Flutter. |

## 5. Assumptions

- Single demo traveller per install (no multi-profile switching in v1).
- eSIM provisioning, carrier negotiation, and real telecom signaling are
  **simulated** — RoamPulse never touches real carrier infrastructure.
- "Live" backend data is itself seeded/synthetic; Chaos Mode is the tool for
  demonstrating real-world failure handling rather than an actual unreliable
  upstream.
- One backend serves one Flutter client; no multi-tenant concerns.
- Push notifications, payments, and plan purchase flows are out of scope —
  RoamPulse assumes a plan already exists.

## 6. Constraints

- Portfolio project, built and demoed by one engineer — architecture must
  stay explainable in a 5–10 minute interview (see §48 "no fake seniority").
- No paid infrastructure requirement: PostgreSQL + a single Go binary must be
  runnable locally (or in a free-tier container) without Kubernetes, Kafka,
  or Redis.
- Claude API key must never be embedded in the Flutter client — all AI calls
  are backend-mediated.
- Native widget work is scoped to Android (App Widget, Kotlin/Glance or
  RemoteViews) and iOS (WidgetKit/SwiftUI) — no watchOS/macOS widget.

## 7. Product principles

1. **Never lie about freshness.** Cached data is always visibly cached.
2. **Reassure by default, alarm only when true.** Calm tone until there's a
   real, actionable problem.
3. **Determinism before AI.** Every diagnosis must be explainable without
   Claude; AI adds a better explanation, not the only explanation.
4. **Offline is a first-class state, not an error.** The app has a designed
   offline UI, not a generic error screen.
5. **Boring in the right places.** Auth, infra, and dependency choices stay
   simple so complexity budget goes toward connectivity/offline/AI — the
   parts that actually demonstrate the role's requirements.

## 8. Success metrics (hypothetical — instrumented, not real production data)

| Metric | What it demonstrates |
|---|---|
| Time to first meaningful paint on dashboard | Parallel API loading, performance discipline |
| Cache hit rate on cold start | Offline-first effectiveness |
| % of outage scenarios where UI remains usable (non-blank) | Resilience |
| Diagnostic engine agreement rate vs. AI agent | AI is additive, not load-bearing |
| AI fallback rate (Claude unavailable → deterministic path used) | Graceful degradation |
| Sync duration after reconnect | Sync architecture efficiency |

## 9. MVP definition

The MVP is the full primary user journey (§3) running end-to-end against the
Go backend with seeded demo data, including: dashboard, connectivity domain,
offline cache + resync, deterministic diagnostics, one native widget
platform fully working (the other stubbed if time-constrained), and the
Claude recovery agent with validated structured output and fallback. Chaos
Mode is part of the MVP because it is the only way to demo resilience
on-demand during an interview.

## 10. Future opportunities (explicitly out of scope now)

- Multiple concurrent trips / trip history.
- Real OAuth (Google/Apple) — interfaces reserved, not implemented.
- Push notifications for plan expiry / outage.
- Multi-traveller / family plan view.
- Real carrier API integration.

## 11. Feature list (traced to the journey above)

- Demo authentication (entry point, swappable later).
- Dashboard: traveller, destination, network, connection state, data
  remaining, plan expiry, usage breakdown, connection quality, recent events,
  recommended action.
- Connectivity domain + `ConnectivityBloc` with explicit state machine.
- Offline-first repository layer (cache, TTL, stale-while-revalidate, sync).
- Deterministic diagnostic engine.
- Claude-powered Connectivity Recovery Agent with tool use + validation.
- Chaos Mode (dev-only failure simulation).
- Native Android widget + iOS WidgetKit, fed via a `NativeWidgetService`
  bridge.
- Design system package (calm/trustworthy visual language).

## 12. Key risks

| Risk | Mitigation |
|---|---|
| Scope creep across 15 phases stalls MVP | Strict phase gating; each phase has an acceptance check before the next starts. |
| Native widget work balloons (two platforms, two languages) | Define the Flutter-side contract and tests first; native implementations can be minimal-but-real. |
| AI integration becomes the single point of failure | Deterministic diagnostics ship first and always remain the fallback (§14, §17). |
| Monorepo/package boundaries added without real ownership reasons | Each package must justify itself against §19/§48 before creation. |
| Backend becomes a toy that doesn't reflect real API design | Versioned REST, structured errors, and proper migrations from Phase 2 onward. |
