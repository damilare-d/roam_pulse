// Command api runs the RoamPulse backend HTTP server.
package main

import (
	"context"
	"log"
	"net/http"
	"time"

	"roampulse/backend/internal/config"
	"roampulse/backend/internal/httpapi"
	"roampulse/backend/internal/postgres"
	"roampulse/backend/internal/service"
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

	travellers := postgres.NewTravellerRepo(pool)
	plans := postgres.NewPlanRepo(pool)
	destinations := postgres.NewDestinationRepo(pool)
	networks := postgres.NewNetworkRepo(pool)
	connectivity := postgres.NewConnectivityRepo(pool)
	esims := postgres.NewEsimRepo(pool)
	diagnosticsRepo := postgres.NewDiagnosticRepo(pool)

	diagnosticsService := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnosticsRepo)
	claudeClient := service.NewClaudeClient(cfg.AnthropicAPIKey)

	router := httpapi.NewRouter(httpapi.Services{
		Auth:         service.NewAuthService(travellers),
		Profile:      service.NewProfileService(travellers),
		Trip:         service.NewTripService(travellers, plans, destinations, networks, connectivity),
		Plan:         service.NewPlanService(travellers, plans),
		Usage:        service.NewUsageService(travellers, plans),
		Connectivity: service.NewConnectivityService(travellers, plans, networks, connectivity),
		Destination:  service.NewDestinationService(destinations),
		Network:      service.NewNetworkService(networks),
		Diagnostics:  diagnosticsService,
		AIRecovery:   service.NewAIRecoveryService(diagnosticsService, claudeClient, diagnosticsRepo),
	})

	server := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("roampulse backend listening on :%s", cfg.Port)
	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
