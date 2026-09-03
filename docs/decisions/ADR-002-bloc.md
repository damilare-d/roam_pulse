# ADR-002: BLoC as the sole state-management mechanism

## Context

RoamPulse's connectivity domain (Phase 5) has genuine asynchronous
lifecycle: connecting → connected → degraded → offline → synchronizing →
error, driven by both user action and background events (a lost signal,
a completed sync). That's a state machine, not a value to display — the
kind of complexity BLoC's explicit event/state contract is built for. The
build brief also mandates BLoC as the only primary state-management
framework (no Provider/Riverpod/GetX/MobX/Redux).

## Decision

`flutter_bloc` for every feature with real state lifecycle. `DashboardBloc`
(Phase 3) is the reference shape: a `sealed class` of events, a
`sealed class` of states, and a single `on<Event>` handler per event —
established now so `ConnectivityBloc`, `PlanBloc`, `DiagnosticsBloc`, etc.
(Phase 5+) follow the same pattern rather than each inventing its own.

States and events are `sealed class` hierarchies (Dart 3), switched over
exhaustively in the UI (`switch (state) { ... }` with no default case) —
the compiler, not a runtime check, catches an unhandled state.

Per §21 of the brief: not every widget gets a BLoC. A BLoC is for state
with lifecycle or business behaviour; a widget's own open/closed toggle or
animation state stays local `StatefulWidget` state.

`flutter_bloc`'s `RepositoryProvider`/`BlocProvider` (both re-exported
from `provider` internally) are used for dependency injection — no
separate service-locator package (`get_it` etc.) is introduced, since
`flutter_bloc` already provides everything RoamPulse's DI needs.

## Alternatives considered

- **Riverpod / Provider / GetX / MobX / Redux**: excluded by the brief
  directly (§1, §21) — the project exists partly to demonstrate BLoC
  specifically for a role that names it as a requirement.
- **A BLoC per screen regardless of complexity**: rejected — would violate
  §21's "don't create a BLoC for every widget." Simple display-only
  screens (once they exist) render straight from a parent BLoC's state or
  local widget state instead.

## Trade-offs

- `sealed class` events/states means every new event handler is written
  by hand (no codegen) — more boilerplate per BLoC than, say, a single
  `Cubit` method call, but it's what gives the exhaustive-switch safety
  above.

## Consequences

- `DashboardBloc`, `DashboardEvent`, `DashboardState` in
  `apps/mobile/lib/features/dashboard/dashboard_bloc.dart` are the
  template Phase 5's `ConnectivityBloc` copies structurally.
