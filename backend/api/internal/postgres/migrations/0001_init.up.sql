-- Core schema for RoamPulse: travellers, plans, connectivity, and
-- diagnostics. See docs/ARCHITECTURE.md section 6 for the data model
-- narrative. Status/state/category fields use CHECK constraints instead of
-- native enum types so new values don't require ALTER TYPE migrations.

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT NOT NULL UNIQUE,
    auth_provider TEXT NOT NULL DEFAULT 'demo'
                  CHECK (auth_provider IN ('demo', 'jwt', 'google', 'apple')),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE traveller_profiles (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    home_country TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_traveller_profiles_user_id ON traveller_profiles(user_id);

CREATE TABLE destinations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code TEXT NOT NULL,
    city         TEXT NOT NULL,
    timezone     TEXT NOT NULL
);

CREATE TABLE networks (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    destination_id UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
    carrier_name   TEXT NOT NULL,
    technology     TEXT NOT NULL CHECK (technology IN ('2G', '3G', '4G', '5G')),
    mcc            TEXT NOT NULL,
    mnc            TEXT NOT NULL
);
CREATE INDEX idx_networks_destination_id ON networks(destination_id);

CREATE TABLE esims (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveller_id    UUID NOT NULL REFERENCES traveller_profiles(id) ON DELETE CASCADE,
    iccid_simulated TEXT NOT NULL UNIQUE,
    status          TEXT NOT NULL DEFAULT 'inactive'
                    CHECK (status IN ('inactive', 'active', 'suspended', 'expired')),
    activated_at    TIMESTAMPTZ
);
CREATE INDEX idx_esims_traveller_id ON esims(traveller_id);

CREATE TABLE travel_plans (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveller_id      UUID NOT NULL REFERENCES traveller_profiles(id) ON DELETE CASCADE,
    destination_id    UUID NOT NULL REFERENCES destinations(id),
    esim_id           UUID NOT NULL REFERENCES esims(id),
    starts_at         TIMESTAMPTZ NOT NULL,
    expires_at        TIMESTAMPTZ NOT NULL,
    data_allowance_mb INTEGER NOT NULL CHECK (data_allowance_mb > 0),
    status            TEXT NOT NULL DEFAULT 'upcoming'
                      CHECK (status IN ('upcoming', 'active', 'completed', 'expired')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_travel_plans_traveller_id ON travel_plans(traveller_id);
CREATE INDEX idx_travel_plans_status ON travel_plans(status);
-- Demo product assumption: a traveller has at most one active trip.
CREATE UNIQUE INDEX one_active_plan_per_traveller
    ON travel_plans(traveller_id) WHERE status = 'active';

CREATE TABLE network_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id         UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    network_id      UUID NOT NULL REFERENCES networks(id),
    connected_at    TIMESTAMPTZ NOT NULL,
    disconnected_at TIMESTAMPTZ,
    signal_strength TEXT CHECK (signal_strength IN ('none', 'weak', 'moderate', 'strong')),
    latency_ms      INTEGER
);
CREATE INDEX idx_network_sessions_plan_id ON network_sessions(plan_id);

CREATE TABLE usage_records (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id     UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ NOT NULL,
    category    TEXT NOT NULL CHECK (category IN ('maps', 'social', 'video', 'browsing', 'other')),
    bytes_used  BIGINT NOT NULL CHECK (bytes_used >= 0)
);
CREATE INDEX idx_usage_records_plan_id ON usage_records(plan_id, recorded_at);

CREATE TABLE connectivity_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id     UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    occurred_at TIMESTAMPTZ NOT NULL,
    from_state  TEXT NOT NULL CHECK (from_state IN
                ('unknown', 'connecting', 'connected', 'degraded', 'offline', 'synchronizing', 'error')),
    to_state    TEXT NOT NULL CHECK (to_state IN
                ('unknown', 'connecting', 'connected', 'degraded', 'offline', 'synchronizing', 'error')),
    reason      TEXT
);
CREATE INDEX idx_connectivity_events_plan_id ON connectivity_events(plan_id, occurred_at DESC);

CREATE TABLE diagnostic_sessions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id      UUID NOT NULL REFERENCES travel_plans(id) ON DELETE CASCADE,
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    trigger      TEXT NOT NULL CHECK (trigger IN ('user_initiated', 'auto_degraded', 'auto_offline'))
);
CREATE INDEX idx_diagnostic_sessions_plan_id ON diagnostic_sessions(plan_id);

CREATE TABLE diagnostic_results (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES diagnostic_sessions(id) ON DELETE CASCADE,
    engine          TEXT NOT NULL CHECK (engine IN ('deterministic', 'ai')),
    issue           TEXT NOT NULL,
    confidence      DOUBLE PRECISION NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
    severity        TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high')),
    recommendation  TEXT NOT NULL,
    raw_payload     JSONB NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_diagnostic_results_session_id ON diagnostic_results(session_id);

CREATE TABLE sync_metadata (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    traveller_id   UUID NOT NULL REFERENCES traveller_profiles(id) ON DELETE CASCADE,
    resource       TEXT NOT NULL,
    last_synced_at TIMESTAMPTZ NOT NULL,
    checksum       TEXT NOT NULL,
    UNIQUE (traveller_id, resource)
);
