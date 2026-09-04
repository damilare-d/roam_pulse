// Package repository defines the persistence ports the service layer
// depends on. internal/postgres provides the only implementation today;
// the interfaces exist so services stay testable against fakes without a
// database, and so the storage engine could change without touching
// service or handler code.
package repository

import (
	"context"

	"roampulse/backend/internal/domain"
)

// TravellerRepository reads the single demo traveller. RoamPulse's demo
// auth mode has exactly one traveller per install (see
// docs/PRODUCT_DISCOVERY.md assumptions) — traveller-scoping by ID is
// deferred until real auth (ADR-010) replaces this.
type TravellerRepository interface {
	GetDemoProfile(ctx context.Context) (*domain.TravellerProfile, error)
}

type PlanRepository interface {
	GetCurrentPlan(ctx context.Context, travellerID string) (*domain.TravelPlan, error)
	GetUsage(ctx context.Context, planID string) ([]domain.UsageRecord, error)
}

type EsimRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Esim, error)
}

type DestinationRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Destination, error)
}

type NetworkRepository interface {
	GetByID(ctx context.Context, id string) (*domain.Network, error)
}

type ConnectivityRepository interface {
	GetLatestSession(ctx context.Context, planID string) (*domain.NetworkSession, error)
	GetRecentEvents(ctx context.Context, planID string, limit int) ([]domain.ConnectivityEvent, error)
}

// DiagnosticRepository persists diagnostic runs. Both the deterministic
// engine (Phase 8) and the AI engine (Phase 11) write to the same
// diagnostic_results table via SaveResult, tagged by
// domain.DiagnosticEngineKind — this is how the two stay auditable and
// comparable rather than living in separate, disconnected logs.
type DiagnosticRepository interface {
	CreateSession(ctx context.Context, planID string, trigger domain.DiagnosticTrigger) (*domain.DiagnosticSession, error)
	SaveResult(ctx context.Context, sessionID string, result domain.DiagnosticResultRecord) error
}
