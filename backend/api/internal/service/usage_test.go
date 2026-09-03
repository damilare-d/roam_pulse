package service_test

import (
	"context"
	"testing"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestGetUsageSummary_AggregatesByCategory(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{
		plan: &domain.TravelPlan{ID: "plan-1"},
		usage: []domain.UsageRecord{
			{Category: "maps", BytesUsed: 100},
			{Category: "maps", BytesUsed: 50},
			{Category: "video", BytesUsed: 400},
			{Category: "other", BytesUsed: 10},
		},
	}

	svc := service.NewUsageService(travellers, plans)
	summary, err := svc.GetUsageSummary(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if summary.TotalBytesUsed != 560 {
		t.Errorf("TotalBytesUsed = %d, want 560", summary.TotalBytesUsed)
	}
	if summary.ByCategory["maps"] != 150 {
		t.Errorf("ByCategory[maps] = %d, want 150", summary.ByCategory["maps"])
	}
	if summary.ByCategory["video"] != 400 {
		t.Errorf("ByCategory[video] = %d, want 400", summary.ByCategory["video"])
	}
}

func TestGetUsageSummary_NoRecords(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1"}}

	svc := service.NewUsageService(travellers, plans)
	summary, err := svc.GetUsageSummary(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if summary.TotalBytesUsed != 0 {
		t.Errorf("TotalBytesUsed = %d, want 0", summary.TotalBytesUsed)
	}
	if len(summary.ByCategory) != 0 {
		t.Errorf("ByCategory should be empty, got %v", summary.ByCategory)
	}
}
