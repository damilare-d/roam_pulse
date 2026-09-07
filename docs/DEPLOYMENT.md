# Deployment

**Live**: https://roam-pulse-psi.vercel.app — Flutter web on Vercel,
calling a real Go + PostgreSQL backend on Render at
https://roampulse-api.onrender.com, with a genuine
`ANTHROPIC_API_KEY` configured (the Connectivity Recovery Agent returns
real Claude answers, not the fallback — see ADR-008).

This exists purely as a portfolio artifact — a link a reviewer can open
without cloning the repo or running Postgres locally. Every architectural
decision elsewhere in this project (offline-first caching, Chaos Mode,
the deterministic-before-AI diagnostic engine) was made independent of
whether a live deployment would ever exist; this is additive, not a
design driver.

## Backend — Render

`render.yaml` (repo root) is a Render Blueprint: a free-tier Postgres 16
instance plus a free-tier Go web service (`rootDir: backend/api`,
`go build -o bin/api ./cmd/api`). Deployed via Render's dashboard → New →
Blueprint → point at this repo; `ANTHROPIC_API_KEY` is entered directly in
Render's UI (`sync: false` in the blueprint — it's never written into the
repo).

**No `preDeployCommand`** — that's a paid-tier-only Render feature.
Seeding instead happens inside `cmd/api`'s own startup
(`postgres.Seed`, right after `postgres.Migrate`): safe to rerun on every
restart since it truncates before inserting, and means every visitor gets
the same pristine Tokyo/SoftBank scenario rather than whatever a previous
visitor's diagnostic runs left behind.

**Free tier means the service spins down when idle** and the first
request after a while takes 30–60s to cold-start. That's Render, not a
bug — worth knowing if you're the one clicking the link cold.

**CORS**: `backend/api/internal/httpapi/cors.go` allows any origin —
there's no cookie- or credential-based auth on this backend to protect
(ADR-010's demo-auth scope decision), so a stricter origin allow-list
wouldn't actually be defending anything.

## Frontend — Vercel, via GitHub Actions

`.github/workflows/deploy-web.yml` builds `flutter build web --release
--dart-define=BACKEND_URL=<the Render URL>` and deploys the prebuilt
`build/web` output to Vercel via the Vercel CLI — Flutter isn't installed
on Vercel's own build image, so building in GitHub Actions (where it
already reliably works, same setup as every other workflow) and deploying
a static directory sidesteps that entirely.

Runs on every push to `main` touching `apps/mobile/**` or `packages/**`,
or manually via `workflow_dispatch`. Needs four values, none of them
committed to the repo:

| Name | Where it lives | Where it comes from |
|---|---|---|
| `VERCEL_TOKEN` | GitHub Actions secret | Vercel → Settings → Tokens |
| `VERCEL_ORG_ID` | GitHub Actions secret | Vercel → Settings → General ("Team ID") |
| `VERCEL_PROJECT_ID` | GitHub Actions secret | Vercel project → Settings → General |
| `BACKEND_URL` | GitHub Actions **variable** (not secret — it's just a public URL) | The deployed Render service's URL |

## Two bugs this deployment surfaced

Both are documented in more detail where the actual fix lives (`main.dart`,
`ApiClient`), but worth naming here since they're specifically
*deployment*-shaped bugs — neither could have been caught by the unit,
widget, or even the local-desktop integration test suite, all of which
predate this deployment and none of which run a real browser against a
real deployed backend:

1. **`_resolveBaseUrl` crashed on web** — it touched `dart:io`'s
   `Platform` unconditionally, which throws on web; needed a `kIsWeb`
   guard checked first. `MethodChannelNativeWidgetService` had the same
   class of bug: `defaultTargetPlatform` alone isn't sufficient to detect
   a native widget host, since it still reports `android`/`iOS` on web
   when the browser's OS matches (it's choosing Material vs. Cupertino
   styling, not asserting a platform-channel host exists).
2. **The AI recovery call timed out client-side** — `ApiClient`'s default
   10s Dio timeout was sized for fast Postgres-backed endpoints; a
   genuine Claude round-trip routinely takes longer. Fixed with a 45s
   per-call `receiveTimeout` override, specifically for that one
   endpoint.

Both were caught by actually opening the deployed link in a browser and
trying it, not by any automated check — the same "live-verify, don't
assume" discipline applied everywhere else in this project turned out to
matter here too.
