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

type PlanRepo struct {
	pool *pgxpool.Pool
}

func NewPlanRepo(pool *pgxpool.Pool) *PlanRepo {
	return &PlanRepo{pool: pool}
}

func (r *PlanRepo) GetCurrentPlan(ctx context.Context, travellerID string) (*domain.TravelPlan, error) {
	const query = `
		SELECT id, traveller_id, destination_id, esim_id, starts_at, expires_at,
		       data_allowance_mb, status
		FROM travel_plans
		WHERE traveller_id = $1 AND status = 'active'
	`

	var p domain.TravelPlan
	err := r.pool.QueryRow(ctx, query, travellerID).Scan(
		&p.ID, &p.TravellerID, &p.DestinationID, &p.EsimID,
		&p.StartsAt, &p.ExpiresAt, &p.DataAllowanceMB, &p.Status,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("traveller has no active trip")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get current plan: %w", err)
	}

	return &p, nil
}

func (r *PlanRepo) GetUsage(ctx context.Context, planID string) ([]domain.UsageRecord, error) {
	const query = `
		SELECT id, plan_id, recorded_at, category, bytes_used
		FROM usage_records
		WHERE plan_id = $1
		ORDER BY recorded_at
	`

	rows, err := r.pool.Query(ctx, query, planID)
	if err != nil {
		return nil, fmt.Errorf("postgres: get usage: %w", err)
	}
	defer rows.Close()

	var records []domain.UsageRecord
	for rows.Next() {
		var u domain.UsageRecord
		if err := rows.Scan(&u.ID, &u.PlanID, &u.RecordedAt, &u.Category, &u.BytesUsed); err != nil {
			return nil, fmt.Errorf("postgres: scan usage record: %w", err)
		}
		records = append(records, u)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("postgres: iterate usage records: %w", err)
	}

	return records, nil
}
