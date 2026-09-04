package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/repository"
)

type DiagnosticService struct {
	travellers   repository.TravellerRepository
	plans        repository.PlanRepository
	esims        repository.EsimRepository
	connectivity repository.ConnectivityRepository
	diagnostics  repository.DiagnosticRepository
}

func NewDiagnosticService(
	travellers repository.TravellerRepository,
	plans repository.PlanRepository,
	esims repository.EsimRepository,
	connectivity repository.ConnectivityRepository,
	diagnostics repository.DiagnosticRepository,
) *DiagnosticService {
	return &DiagnosticService{
		travellers:   travellers,
		plans:        plans,
		esims:        esims,
		connectivity: connectivity,
		diagnostics:  diagnostics,
	}
}

// RunDiagnostics gathers the traveller's current plan/eSIM/network state,
// runs the deterministic engine (never Claude — see ADR-009), and persists
// both the session and result so this run is auditable alongside any
// future AI-engine run on the same plan (domain.DiagnosticEngineAI writes
// to the same table in Phase 11).
func (s *DiagnosticService) RunDiagnostics(ctx context.Context) (*Diagnosis, error) {
	traveller, err := s.travellers.GetDemoProfile(ctx)
	if err != nil {
		return nil, fmt.Errorf("diagnostic service: get traveller: %w", err)
	}

	plan, err := s.plans.GetCurrentPlan(ctx, traveller.ID)
	if err != nil {
		return nil, fmt.Errorf("diagnostic service: get current plan: %w", err)
	}

	esim, err := s.esims.GetByID(ctx, plan.EsimID)
	if err != nil {
		return nil, fmt.Errorf("diagnostic service: get esim: %w", err)
	}

	session, err := s.connectivity.GetLatestSession(ctx, plan.ID)
	if err != nil {
		return nil, fmt.Errorf("diagnostic service: get latest session: %w", err)
	}

	diagnosis := Diagnose(DiagnosticInput{
		PlanActive:        plan.Status == domain.PlanStatusActive,
		EsimActive:        esim.Status == domain.EsimStatusActive,
		NetworkRegistered: session.DisconnectedAt == nil,
		SignalStrength:    session.SignalStrength,
		LatencyMs:         session.LatencyMs,
	})

	// A logging failure shouldn't deny the traveller a diagnosis they're
	// actively waiting on — log and continue rather than fail the request.
	if err := s.persist(ctx, plan.ID, diagnosis); err != nil {
		log.Printf("diagnostic service: failed to persist diagnostic run: %v", err)
	}

	return &diagnosis, nil
}

func (s *DiagnosticService) persist(ctx context.Context, planID string, d Diagnosis) error {
	session, err := s.diagnostics.CreateSession(ctx, planID, domain.DiagnosticTriggerUserInitiated)
	if err != nil {
		return fmt.Errorf("create session: %w", err)
	}

	payload, err := json.Marshal(d)
	if err != nil {
		return fmt.Errorf("marshal diagnosis: %w", err)
	}

	return s.diagnostics.SaveResult(ctx, session.ID, domain.DiagnosticResultRecord{
		Engine:         domain.DiagnosticEngineDeterministic,
		Issue:          d.Issue,
		Confidence:     d.Confidence,
		Severity:       d.Severity,
		Recommendation: d.Recommendation,
		RawPayload:     payload,
	})
}
