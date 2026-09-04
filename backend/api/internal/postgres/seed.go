package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Deterministic demo IDs so screenshots and demo runs are reproducible —
// see docs/PRODUCT_DISCOVERY.md section 35.
const (
	demoUserID      = "00000000-0000-0000-0000-000000000001"
	demoTravellerID = "00000000-0000-0000-0000-000000000002"

	destJapanID  = "00000000-0000-0000-0000-0000000000a1"
	destFranceID = "00000000-0000-0000-0000-0000000000a2"
	destSpainID  = "00000000-0000-0000-0000-0000000000a3"
	destItalyID  = "00000000-0000-0000-0000-0000000000a4"

	networkSoftBankID = "00000000-0000-0000-0000-0000000000b1"
	networkOrangeID   = "00000000-0000-0000-0000-0000000000b2"
	networkMovistarID = "00000000-0000-0000-0000-0000000000b3"
	networkTimID      = "00000000-0000-0000-0000-0000000000b4"

	esimJapanID  = "00000000-0000-0000-0000-0000000000c1"
	esimFranceID = "00000000-0000-0000-0000-0000000000c2"
	esimSpainID  = "00000000-0000-0000-0000-0000000000c3"
	esimItalyID  = "00000000-0000-0000-0000-0000000000c4"

	planJapanID  = "00000000-0000-0000-0000-0000000000d1"
	planFranceID = "00000000-0000-0000-0000-0000000000d2"
	planSpainID  = "00000000-0000-0000-0000-0000000000d3"
	planItalyID  = "00000000-0000-0000-0000-0000000000d4"
)

// Seed truncates and repopulates every domain table with a deterministic
// demo traveller: one active, healthy trip (Tokyo) plus three completed
// historical trips illustrating degraded, offline, and expired outcomes.
// Chaos Mode (Phase 9) mutates the *active* trip's live state at demo time
// rather than needing a scenario switcher here — see ADR discussion in
// docs/PRODUCT_DISCOVERY.md section 35.
func Seed(ctx context.Context, pool *pgxpool.Pool) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("seed: begin transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	const truncate = `
		TRUNCATE sync_metadata, diagnostic_results, diagnostic_sessions,
		         connectivity_events, usage_records, network_sessions,
		         travel_plans, esims, networks, destinations,
		         traveller_profiles, users
	`
	if _, err := tx.Exec(ctx, truncate); err != nil {
		return fmt.Errorf("seed: truncate: %w", err)
	}

	now := time.Now().UTC()

	if _, err := tx.Exec(ctx,
		`INSERT INTO users (id, email, auth_provider) VALUES ($1, $2, 'demo')`,
		demoUserID, "demo.traveller@roampulse.app",
	); err != nil {
		return fmt.Errorf("seed: insert user: %w", err)
	}

	if _, err := tx.Exec(ctx,
		`INSERT INTO traveller_profiles (id, user_id, display_name, home_country) VALUES ($1, $2, $3, $4)`,
		demoTravellerID, demoUserID, "Alex Morgan", "United Kingdom",
	); err != nil {
		return fmt.Errorf("seed: insert traveller profile: %w", err)
	}

	destinations := []struct{ id, countryCode, city, timezone string }{
		{destJapanID, "JP", "Tokyo", "Asia/Tokyo"},
		{destFranceID, "FR", "Paris", "Europe/Paris"},
		{destSpainID, "ES", "Barcelona", "Europe/Madrid"},
		{destItalyID, "IT", "Rome", "Europe/Rome"},
	}
	for _, d := range destinations {
		if _, err := tx.Exec(ctx,
			`INSERT INTO destinations (id, country_code, city, timezone) VALUES ($1, $2, $3, $4)`,
			d.id, d.countryCode, d.city, d.timezone,
		); err != nil {
			return fmt.Errorf("seed: insert destination %s: %w", d.city, err)
		}
	}

	networks := []struct {
		id, destinationID, carrier, technology, mcc, mnc string
	}{
		{networkSoftBankID, destJapanID, "SoftBank", "5G", "440", "20"},
		{networkOrangeID, destFranceID, "Orange", "4G", "208", "01"},
		{networkMovistarID, destSpainID, "Movistar", "4G", "214", "07"},
		{networkTimID, destItalyID, "TIM", "4G", "222", "01"},
	}
	for _, n := range networks {
		if _, err := tx.Exec(ctx,
			`INSERT INTO networks (id, destination_id, carrier_name, technology, mcc, mnc) VALUES ($1, $2, $3, $4, $5, $6)`,
			n.id, n.destinationID, n.carrier, n.technology, n.mcc, n.mnc,
		); err != nil {
			return fmt.Errorf("seed: insert network %s: %w", n.carrier, err)
		}
	}

	esims := []struct {
		id, iccid, status string
		activatedAt       *time.Time
	}{
		{esimJapanID, "8944000000000000001", "active", ptr(now.Add(-48 * time.Hour))},
		{esimFranceID, "8944000000000000002", "expired", ptr(now.Add(-60 * 24 * time.Hour))},
		{esimSpainID, "8944000000000000003", "expired", ptr(now.Add(-120 * 24 * time.Hour))},
		{esimItalyID, "8944000000000000004", "expired", ptr(now.Add(-200 * 24 * time.Hour))},
	}
	for _, e := range esims {
		if _, err := tx.Exec(ctx,
			`INSERT INTO esims (id, traveller_id, iccid_simulated, status, activated_at) VALUES ($1, $2, $3, $4, $5)`,
			e.id, demoTravellerID, e.iccid, e.status, e.activatedAt,
		); err != nil {
			return fmt.Errorf("seed: insert esim %s: %w", e.iccid, err)
		}
	}

	plans := []struct {
		id, destinationID, esimID string
		startsAt, expiresAt       time.Time
		dataAllowanceMB           int
		status                    string
	}{
		{planJapanID, destJapanID, esimJapanID, now.Add(-48 * time.Hour), now.Add(4 * 24 * time.Hour), 8000, "active"},
		{planFranceID, destFranceID, esimFranceID, now.Add(-60 * 24 * time.Hour), now.Add(-53 * 24 * time.Hour), 5000, "completed"},
		{planSpainID, destSpainID, esimSpainID, now.Add(-120 * 24 * time.Hour), now.Add(-113 * 24 * time.Hour), 3000, "completed"},
		{planItalyID, destItalyID, esimItalyID, now.Add(-200 * 24 * time.Hour), now.Add(-199 * 24 * time.Hour), 1000, "expired"},
	}
	for _, p := range plans {
		if _, err := tx.Exec(ctx,
			`INSERT INTO travel_plans (id, traveller_id, destination_id, esim_id, starts_at, expires_at, data_allowance_mb, status)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
			p.id, demoTravellerID, p.destinationID, p.esimID, p.startsAt, p.expiresAt, p.dataAllowanceMB, p.status,
		); err != nil {
			return fmt.Errorf("seed: insert plan %s: %w", p.id, err)
		}
	}

	sessions := []struct {
		planID, networkID string
		connectedAt       time.Time
		disconnectedAt    *time.Time
		signalStrength    string
		latencyMs         *int
		downloadMbps      *float64
		uploadMbps        *float64
	}{
		{planJapanID, networkSoftBankID, now.Add(-48 * time.Hour), nil, "strong", ptr(42), ptr(87.0), ptr(21.0)},
		{
			planFranceID, networkOrangeID, now.Add(-60 * 24 * time.Hour), ptr(now.Add(-59 * 24 * time.Hour)),
			"weak", ptr(320), ptr(3.2), ptr(0.8),
		},
		{planSpainID, networkMovistarID, now.Add(-120 * 24 * time.Hour), ptr(now.Add(-119 * 24 * time.Hour)), "none", nil, nil, nil},
		{
			planItalyID, networkTimID, now.Add(-200 * 24 * time.Hour), ptr(now.Add(-199 * 24 * time.Hour)),
			"moderate", ptr(110), ptr(24.5), ptr(9.1),
		},
	}
	for _, s := range sessions {
		if _, err := tx.Exec(ctx,
			`INSERT INTO network_sessions
			 (plan_id, network_id, connected_at, disconnected_at, signal_strength, latency_ms, download_mbps, upload_mbps)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
			s.planID, s.networkID, s.connectedAt, s.disconnectedAt, s.signalStrength, s.latencyMs, s.downloadMbps, s.uploadMbps,
		); err != nil {
			return fmt.Errorf("seed: insert network session for plan %s: %w", s.planID, err)
		}
	}

	type usageRow struct {
		planID     string
		recordedAt time.Time
		category   string
		bytesUsed  int64
	}
	const mb = 1024 * 1024
	usage := []usageRow{
		{planJapanID, now, "maps", 210 * mb},
		{planJapanID, now, "social", 180 * mb},
		{planJapanID, now, "video", 480 * mb},
		{planJapanID, now, "other", 330 * mb},
		{planFranceID, now.Add(-59 * 24 * time.Hour), "video", 900 * mb},
		{planSpainID, now.Add(-120 * 24 * time.Hour), "maps", 50 * mb},
		{planItalyID, now.Add(-200 * 24 * time.Hour), "other", 200 * mb},
	}
	for _, u := range usage {
		if _, err := tx.Exec(ctx,
			`INSERT INTO usage_records (plan_id, recorded_at, category, bytes_used) VALUES ($1, $2, $3, $4)`,
			u.planID, u.recordedAt, u.category, u.bytesUsed,
		); err != nil {
			return fmt.Errorf("seed: insert usage record for plan %s: %w", u.planID, err)
		}
	}

	type eventRow struct {
		planID     string
		occurredAt time.Time
		fromState  string
		toState    string
		reason     string
	}
	events := []eventRow{
		{planJapanID, now.Add(-48 * time.Hour), "connecting", "connected", "initial connection to SoftBank"},

		{planFranceID, now.Add(-60 * 24 * time.Hour), "connecting", "connected", "initial connection to Orange"},
		{planFranceID, now.Add(-59 * 24 * time.Hour), "connected", "degraded", "high latency and packet loss"},

		{planSpainID, now.Add(-120 * 24 * time.Hour), "connecting", "connected", "initial connection to Movistar"},
		{planSpainID, now.Add(-119 * 24 * time.Hour), "connected", "offline", "network registration lost"},

		{planItalyID, now.Add(-200 * 24 * time.Hour), "connecting", "connected", "initial connection to TIM"},
	}
	for _, e := range events {
		if _, err := tx.Exec(ctx,
			`INSERT INTO connectivity_events (plan_id, occurred_at, from_state, to_state, reason) VALUES ($1, $2, $3, $4, $5)`,
			e.planID, e.occurredAt, e.fromState, e.toState, e.reason,
		); err != nil {
			return fmt.Errorf("seed: insert connectivity event for plan %s: %w", e.planID, err)
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("seed: commit: %w", err)
	}

	return nil
}

func ptr[T any](v T) *T { return &v }
