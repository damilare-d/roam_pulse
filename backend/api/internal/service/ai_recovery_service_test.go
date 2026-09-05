package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

type fakeAIClient struct {
	payload service.AIRecommendationPayloadForTest
	err     error
}

func (f *fakeAIClient) Recommend(ctx context.Context, system, user string) (service.AIRecommendationPayloadForTest, error) {
	return f.payload, f.err
}

func healthyDeps() (*fakeTravellerRepo, *fakePlanRepo, *fakeEsimRepo, *fakeConnectivityRepo) {
	latency := 42
	return &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}},
		&fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", EsimID: "esim-1", Status: domain.PlanStatusActive}},
		&fakeEsimRepo{esim: &domain.Esim{ID: "esim-1", Status: domain.EsimStatusActive}},
		&fakeConnectivityRepo{session: &domain.NetworkSession{
			NetworkID:      "network-1",
			SignalStrength: "strong",
			LatencyMs:      &latency,
			ConnectedAt:    time.Now().Add(-time.Hour),
		}}
}

func TestAIRecoveryService_SuccessfulAICallPersistsBothEngineResultsUnderOneSession(t *testing.T) {
	travellers, plans, esims, connectivity := healthyDeps()
	diagnostics := &fakeDiagnosticRepo{}
	diagnosticService := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	ai := &fakeAIClient{payload: service.AIRecommendationPayloadForTest{
		Summary: "Everything looks fine.", Steps: []string{"No action needed."}, Confidence: 0.95, Escalate: false,
	}}

	svc := service.NewAIRecoveryService(diagnosticService, ai, diagnostics)
	rec, err := svc.GetRecommendation(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if rec.Source != "ai" {
		t.Errorf("Source = %q, want %q", rec.Source, "ai")
	}
	if rec.Summary != "Everything looks fine." {
		t.Errorf("Summary = %q", rec.Summary)
	}

	if len(diagnostics.savedResults) != 2 {
		t.Fatalf("expected 2 persisted results (deterministic + ai), got %d", len(diagnostics.savedResults))
	}
	if diagnostics.savedResults[0].Engine != domain.DiagnosticEngineDeterministic {
		t.Errorf("first result Engine = %q, want %q", diagnostics.savedResults[0].Engine, domain.DiagnosticEngineDeterministic)
	}
	if diagnostics.savedResults[1].Engine != domain.DiagnosticEngineAI {
		t.Errorf("second result Engine = %q, want %q", diagnostics.savedResults[1].Engine, domain.DiagnosticEngineAI)
	}
}

func TestAIRecoveryService_AIClientErrorFallsBackWithoutFailingTheRequest(t *testing.T) {
	travellers, plans, esims, connectivity := healthyDeps()
	diagnostics := &fakeDiagnosticRepo{}
	diagnosticService := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	ai := &fakeAIClient{err: errors.New("connection refused")}

	svc := service.NewAIRecoveryService(diagnosticService, ai, diagnostics)
	rec, err := svc.GetRecommendation(context.Background())
	if err != nil {
		t.Fatalf("expected GetRecommendation to fall back rather than error, got: %v", err)
	}
	if rec.Source != "fallback" {
		t.Errorf("Source = %q, want %q", rec.Source, "fallback")
	}
	if rec.Summary != "Everything looks good" {
		t.Errorf("Summary = %q, want the deterministic diagnosis's issue", rec.Summary)
	}

	if len(diagnostics.savedResults) != 1 {
		t.Fatalf("expected only the deterministic result to persist, got %d", len(diagnostics.savedResults))
	}
	if diagnostics.savedResults[0].Engine != domain.DiagnosticEngineDeterministic {
		t.Errorf("Engine = %q, want %q", diagnostics.savedResults[0].Engine, domain.DiagnosticEngineDeterministic)
	}
}

func TestAIRecoveryService_MalformedAIResponseFallsBackAndDoesNotPersistAnAIResult(t *testing.T) {
	travellers, plans, esims, connectivity := healthyDeps()
	diagnostics := &fakeDiagnosticRepo{}
	diagnosticService := service.NewDiagnosticService(travellers, plans, esims, connectivity, diagnostics)
	ai := &fakeAIClient{payload: service.AIRecommendationPayloadForTest{
		Summary: "Fine", Steps: nil, Confidence: 0.9,
	}}

	svc := service.NewAIRecoveryService(diagnosticService, ai, diagnostics)
	rec, err := svc.GetRecommendation(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if rec.Source != "fallback" {
		t.Errorf("Source = %q, want %q", rec.Source, "fallback")
	}
	if len(diagnostics.savedResults) != 1 {
		t.Fatalf("expected only the deterministic result to persist, got %d", len(diagnostics.savedResults))
	}
}

func TestAIRecoveryService_PropagatesDiagnosisGatheringError(t *testing.T) {
	wantErr := errors.New("plan lookup failed")
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{planErr: wantErr}
	diagnostics := &fakeDiagnosticRepo{}
	diagnosticService := service.NewDiagnosticService(travellers, plans, &fakeEsimRepo{}, &fakeConnectivityRepo{}, diagnostics)

	svc := service.NewAIRecoveryService(diagnosticService, &fakeAIClient{}, diagnostics)
	_, err := svc.GetRecommendation(context.Background())
	if !errors.Is(err, wantErr) {
		t.Fatalf("expected error to wrap %v, got %v", wantErr, err)
	}
}
