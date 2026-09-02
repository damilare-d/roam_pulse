# RoamPulse

**Your connectivity, before you need to ask.**

RoamPulse is a simulated international connectivity companion for
travellers, built as a technical portfolio project demonstrating
production-minded Flutter/Dart, Go, and AI-workflow engineering.

This is not a Holafly clone — it's an original product concept engineered to
exercise the same skills: modular Flutter architecture, BLoC, offline-first
caching, native platform integration, a Go/PostgreSQL backend, and a
constrained AI agent, all under test-first development and CI.

See [`docs/PRODUCT_DISCOVERY.md`](docs/PRODUCT_DISCOVERY.md) for the product
brief, [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the technical
design, and [`docs/HOLAFLY_ROLE_MAPPING.md`](docs/HOLAFLY_ROLE_MAPPING.md)
for how each requirement maps to a concrete, tested feature.

## Status

Phase 1 (monorepo foundation) — in progress. The project is being built in
gated phases; see `docs/PRODUCT_DISCOVERY.md` for the full phase list. A
complete feature list, screenshots, and setup walkthrough land in the
README as each phase ships (final pass in Phase 15).

## Repository structure

```text
roampulse/
├── apps/mobile/        # Flutter application shell
├── packages/            # Modular Flutter packages (see docs/ARCHITECTURE.md)
├── backend/api/          # Go REST API
├── tools/ai/              # AI-assisted development workflow (Phase 12)
├── docs/                   # Product, architecture, and decision docs
├── melos.yaml
└── pubspec.yaml            # Dart pub workspace root
```

## Local setup

Requires Flutter (stable channel) and Go 1.24+.

```bash
# Resolve the whole Dart workspace (Flutter app + all packages)
flutter pub get

# Static analysis + tests across the workspace
dart analyze
dart test packages/core packages/network packages/diagnostics packages/ai_agent packages/analytics
(cd packages/design_system && flutter test)
(cd packages/storage && flutter test)
(cd packages/connectivity && flutter test)
(cd packages/plans && flutter test)
(cd apps/mobile && flutter test)

# Run the Flutter app
(cd apps/mobile && flutter run)

# Run the Go backend
(cd backend/api && go run ./cmd/api)
curl http://localhost:8080/health
```

PostgreSQL setup, environment variables, and the Claude API key
configuration are documented starting Phase 2.
