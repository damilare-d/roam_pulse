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

type NetworkRepo struct {
	pool *pgxpool.Pool
}

func NewNetworkRepo(pool *pgxpool.Pool) *NetworkRepo {
	return &NetworkRepo{pool: pool}
}

func (r *NetworkRepo) GetByID(ctx context.Context, id string) (*domain.Network, error) {
	const query = `
		SELECT id, destination_id, carrier_name, technology, mcc, mnc
		FROM networks
		WHERE id = $1
	`

	var n domain.Network
	err := r.pool.QueryRow(ctx, query, id).Scan(
		&n.ID, &n.DestinationID, &n.CarrierName, &n.Technology, &n.MCC, &n.MNC,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, apperror.NotFound("network not found")
	}
	if err != nil {
		return nil, fmt.Errorf("postgres: get network: %w", err)
	}

	return &n, nil
}
