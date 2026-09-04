package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestRunDiagnostics_HealthyPlanReportsNoIssues(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", EsimID: "esim-1", Status: domain.PlanStatusActive}}
	esims := &fakeEsimRepo{esim: &domain.Esim{ID: "esim-1", Status: domain.EsimStatusActive}}
	latency := 42
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{
			NetworkID:      "network-1",
			SignalStrength: "strong",
			LatencyMs:      &latency,
			ConnectedAt:    time.Now().Add(-time.Hour),
		},
		events: []domain.ConnectivityEvent{{OccurredAt: time.Now().Add(-time.Minute)}},
	}
	diagnostics := &fakeDiagnosticRepo{}

	svc := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	diagnosis, err := svc.RunDiagnostics(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if diagnosis.Issue != "Everything looks good" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Everything looks good")
	}
	if len(diagnostics.savedResults) != 1 {
		t.Fatalf("expected 1 persisted result, got %d", len(diagnostics.savedResults))
	}
	if diagnostics.savedResults[0].Engine != domain.DiagnosticEngineDeterministic {
		t.Errorf("Engine = %q, want %q", diagnostics.savedResults[0].Engine, domain.DiagnosticEngineDeterministic)
	}
}

func TestRunDiagnostics_DisconnectedSessionMeansNetworkNotRegistered(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", EsimID: "esim-1", Status: domain.PlanStatusActive}}
	esims := &fakeEsimRepo{esim: &domain.Esim{ID: "esim-1", Status: domain.EsimStatusActive}}
	disconnectedAt := time.Now().Add(-time.Minute)
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{
			NetworkID:      "network-1",
			SignalStrength: "none",
			DisconnectedAt: &disconnectedAt,
			ConnectedAt:    time.Now().Add(-time.Hour),
		},
	}
	diagnostics := &fakeDiagnosticRepo{}

	svc := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	diagnosis, err := svc.RunDiagnostics(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if diagnosis.Issue != "Network unavailable" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Network unavailable")
	}
}

func TestRunDiagnostics_ExpiredPlanIsDetected(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", EsimID: "esim-1", Status: domain.PlanStatusExpired}}
	esims := &fakeEsimRepo{esim: &domain.Esim{ID: "esim-1", Status: domain.EsimStatusExpired}}
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{NetworkID: "network-1", SignalStrength: "strong", ConnectedAt: time.Now()},
	}
	diagnostics := &fakeDiagnosticRepo{}

	svc := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	diagnosis, err := svc.RunDiagnostics(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if diagnosis.Issue != "Plan not active" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Plan not active")
	}
}

func TestRunDiagnostics_StillReturnsADiagnosisWhenPersistingFails(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", EsimID: "esim-1", Status: domain.PlanStatusActive}}
	esims := &fakeEsimRepo{esim: &domain.Esim{ID: "esim-1", Status: domain.EsimStatusActive}}
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{NetworkID: "network-1", SignalStrength: "strong", ConnectedAt: time.Now()},
	}
	diagnostics := &fakeDiagnosticRepo{createErr: errors.New("db unavailable")}

	svc := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	diagnosis, err := svc.RunDiagnostics(context.Background())
	if err != nil {
		t.Fatalf("expected RunDiagnostics to succeed even if persisting the audit trail fails, got: %v", err)
	}
	if diagnosis == nil {
		t.Fatal("expected a non-nil diagnosis")
	}
}

func TestRunDiagnostics_PropagatesRepositoryError(t *testing.T) {
	wantErr := errors.New("plan lookup failed")
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{planErr: wantErr}

	svc := service.NewDiagnosticService(travellers, plans, &fakeEsimRepo{}, &fakeConnectivityRepo{}, &fakeDiagnosticRepo{})
	_, err := svc.RunDiagnostics(context.Background())
	if !errors.Is(err, wantErr) {
		t.Fatalf("expected error to wrap %v, got %v", wantErr, err)
	}
}
