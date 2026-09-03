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

type TravellerRepo struct {
	pool *pgxpool.Pool
}

func NewTravellerRepo(pool *pgxpool.Pool) *TravellerRepo {
	return &TravellerRepo{pool: pool}
}

// GetDemoProfile returns the single seeded demo traveller — see the
// TravellerRepository doc comment for why there's no traveller ID param.
func (r *TravellerRepo) GetDemoProfile(ctx context.Context) (*domain.TravellerProfile, error) {
	const query = `
		SELECT id, display_name, home_country, created_at
		FROM traveller_profiles
		ORDER BY created_at
		LIMIT 1
	`

	var p domain.TravellerProfile
	err := r.pool.QueryRow(ctx, query).Scan(&p.ID, &p.DisplayName, &p.HomeCountry, &p.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("no demo traveller has been seeded")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get demo profile: %w", err)
	}

	return &p, nil
}
