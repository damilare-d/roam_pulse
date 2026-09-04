package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"

	"roampulse/backend/internal/domain"
)

type DiagnosticRepo struct {
	pool *pgxpool.Pool
}

func NewDiagnosticRepo(pool *pgxpool.Pool) *DiagnosticRepo {
	return &DiagnosticRepo{pool: pool}
}

func (r *DiagnosticRepo) CreateSession(
	ctx context.Context,
	planID string,
	trigger domain.DiagnosticTrigger,
) (*domain.DiagnosticSession, error) {
	const query = `
		INSERT INTO diagnostic_sessions (plan_id, trigger)
		VALUES ($1, $2)
		RETURNING id, plan_id, started_at, completed_at, trigger
	`

	var s domain.DiagnosticSession
	err := r.pool.QueryRow(ctx, query, planID, trigger).Scan(
		&s.ID, &s.PlanID, &s.StartedAt, &s.CompletedAt, &s.Trigger,
	)
	if err != nil {
		return nil, fmt.Errorf("postgres: create diagnostic session: %w", err)
	}

	return &s, nil
}

func (r *DiagnosticRepo) SaveResult(ctx context.Context, sessionID string, result domain.DiagnosticResultRecord) error {
	const query = `
		INSERT INTO diagnostic_results (session_id, engine, issue, confidence, severity, recommendation, raw_payload)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	if _, err := r.pool.Exec(ctx, query,
		sessionID, result.Engine, result.Issue, result.Confidence, result.Severity, result.Recommendation, result.RawPayload,
	); err != nil {
		return fmt.Errorf("postgres: save diagnostic result: %w", err)
	}

	if _, err := r.pool.Exec(ctx,
		`UPDATE diagnostic_sessions SET completed_at = now() WHERE id = $1`, sessionID,
	); err != nil {
		return fmt.Errorf("postgres: mark diagnostic session complete: %w", err)
	}

	return nil
}
