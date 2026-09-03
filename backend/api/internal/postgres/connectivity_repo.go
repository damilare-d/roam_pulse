package postgres

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"roampulse/backend/internal/apperror"
	"roampulse/backend/internal/domain"
)

type ConnectivityRepo struct {
	pool *pgxpool.Pool
}

func NewConnectivityRepo(pool *pgxpool.Pool) *ConnectivityRepo {
	return &ConnectivityRepo{pool: pool}
}

func (r *ConnectivityRepo) GetLatestSession(ctx context.Context, planID string) (*domain.NetworkSession, error) {
	const query = `
		SELECT id, plan_id, network_id, connected_at, disconnected_at,
		       COALESCE(signal_strength, ''), latency_ms
		FROM network_sessions
		WHERE plan_id = $1
		ORDER BY connected_at DESC
		LIMIT 1
	`

	var s domain.NetworkSession
	err := r.pool.QueryRow(ctx, query, planID).Scan(
		&s.ID, &s.PlanID, &s.NetworkID, &s.ConnectedAt, &s.DisconnectedAt,
		&s.SignalStrength, &s.LatencyMs,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("no network session recorded for this trip")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get latest session: %w", err)
	}

	return &s, nil
}

func (r *ConnectivityRepo) GetRecentEvents(ctx context.Context, planID string, limit int) ([]domain.ConnectivityEvent, error) {
	const query = `
		SELECT id, plan_id, occurred_at, from_state, to_state, COALESCE(reason, '')
		FROM connectivity_events
		WHERE plan_id = $1
		ORDER BY occurred_at DESC
		LIMIT $2
	`

	rows, err := r.pool.Query(ctx, query, planID, limit)
	if err != nil {
		return nil, fmt.Errorf("postgres: get recent events: %w", err)
	}
	defer rows.Close()

	var events []domain.ConnectivityEvent
	for rows.Next() {
		var e domain.ConnectivityEvent
		if err := rows.Scan(&e.ID, &e.PlanID, &e.OccurredAt, &e.FromState, &e.ToState, &e.Reason); err != nil {
			return nil, fmt.Errorf("postgres: scan connectivity event: %w", err)
		}
		events = append(events, e)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("postgres: iterate connectivity events: %w", err)
	}

	return events, nil
}
