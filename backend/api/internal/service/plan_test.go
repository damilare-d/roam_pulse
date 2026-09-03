package service_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestGetCurrentPlanSummary_ComputesRemainingData(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{
		plan: &domain.TravelPlan{
			ID:              "plan-1",
			DataAllowanceMB: 8000,
			ExpiresAt:       time.Now().Add(4*24*time.Hour + time.Hour),
		},
		usage: []domain.UsageRecord{
			{BytesUsed: 600 * 1024 * 1024},
			{BytesUsed: 200 * 1024 * 1024},
		},
	}

	svc := service.NewPlanService(travellers, plans)
	summary, err := svc.GetCurrentPlanSummary(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if summary.DataUsedMB != 800 {
		t.Errorf("DataUsedMB = %v, want 800", summary.DataUsedMB)
	}
	if summary.DataRemainingMB != 7200 {
		t.Errorf("DataRemainingMB = %v, want 7200", summary.DataRemainingMB)
	}
	if summary.DaysRemaining != 4 {
		t.Errorf("DaysRemaining = %v, want 4", summary.DaysRemaining)
	}
}

func TestGetCurrentPlanSummary_ClampsRemainingDataAtZero(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{
		plan: &domain.TravelPlan{
			ID:              "plan-1",
			DataAllowanceMB: 100,
			ExpiresAt:       time.Now().Add(-time.Hour), // already expired
		},
		usage: []domain.UsageRecord{
			{BytesUsed: 500 * 1024 * 1024}, // well over allowance
		},
	}

	svc := service.NewPlanService(travellers, plans)
	summary, err := svc.GetCurrentPlanSummary(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if summary.DataRemainingMB != 0 {
		t.Errorf("DataRemainingMB = %v, want 0 (clamped)", summary.DataRemainingMB)
	}
	if summary.DaysRemaining != 0 {
		t.Errorf("DaysRemaining = %v, want 0 (clamped, plan already expired)", summary.DaysRemaining)
	}
}

func TestGetCurrentPlanSummary_PropagatesRepositoryError(t *testing.T) {
	wantErr := errors.New("no active trip")
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{planErr: wantErr}

	svc := service.NewPlanService(travellers, plans)
	_, err := svc.GetCurrentPlanSummary(context.Background())
	if !errors.Is(err, wantErr) {
		t.Fatalf("expected error to wrap %v, got %v", wantErr, err)
	}
}
