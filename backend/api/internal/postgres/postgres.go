// Package postgres holds the PostgreSQL connection pool, schema
// migrations, and repository implementations (the "infrastructure" and
// "repository interface implementation" layers in docs/ARCHITECTURE.md).
package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Connect opens a pooled connection to PostgreSQL and verifies it with a
// ping so startup fails fast if the database is unreachable.
func Connect(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("postgres: create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("postgres: ping: %w", err)
	}

	return pool, nil
}
