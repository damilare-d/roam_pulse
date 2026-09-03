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

type DestinationRepo struct {
	pool *pgxpool.Pool
}

func NewDestinationRepo(pool *pgxpool.Pool) *DestinationRepo {
	return &DestinationRepo{pool: pool}
}

func (r *DestinationRepo) GetByID(ctx context.Context, id string) (*domain.Destination, error) {
	const query = `SELECT id, country_code, city, timezone FROM destinations WHERE id = $1`

	var d domain.Destination
	err := r.pool.QueryRow(ctx, query, id).Scan(&d.ID, &d.CountryCode, &d.City, &d.Timezone)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("destination not found")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get destination: %w", err)
	}

	return &d, nil
}
