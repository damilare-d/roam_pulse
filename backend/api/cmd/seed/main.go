// Command seed loads deterministic demo data into the RoamPulse database.
// Run after migrations, before starting the API server for the first time:
//
//	go run ./cmd/seed
package main

import (
	"context"
	"log"
	"time"

	"roampulse/backend/internal/config"
	"roampulse/backend/internal/postgres"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	if err := postgres.Migrate(cfg.DatabaseURL); err != nil {
		log.Fatalf("migrate: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := postgres.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("connect: %v", err)
	}
	defer pool.Close()

	if err := postgres.Seed(ctx, pool); err != nil {
		log.Fatalf("seed: %v", err)
	}

	log.Println("seed complete")
}
