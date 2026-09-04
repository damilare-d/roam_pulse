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

type EsimRepo struct {
	pool *pgxpool.Pool
}

func NewEsimRepo(pool *pgxpool.Pool) *EsimRepo {
	return &EsimRepo{pool: pool}
}

func (r *EsimRepo) GetByID(ctx context.Context, id string) (*domain.Esim, error) {
	const query = `
		SELECT id, traveller_id, iccid_simulated, status, activated_at
		FROM esims
		WHERE id = $1
	`

	var e domain.Esim
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&e.ID, &e.TravellerID, &e.IccidSimulated, &e.Status, &e.ActivatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("esim not found")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get esim: %w", err)
	}

	return &e, nil
}
