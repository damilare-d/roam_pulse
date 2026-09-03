package service

import (
	"context"
	"fmt"

	"roampulse/backend/internal/repository"
)

type UsageService struct {
	travellers repository.TravellerRepository
	plans      repository.PlanRepository
}

func NewUsageService(travellers repository.TravellerRepository, plans repository.PlanRepository) *UsageService {
	return &UsageService{travellers: travellers, plans: plans}
}

func (s *UsageService) GetUsageSummary(ctx context.Context) (*UsageSummary, error) {
	traveller, err := s.travellers.GetDemoProfile(ctx)
	if err != nil {
		return nil, fmt.Errorf("usage service: get traveller: %w", err)
	}

	plan, err := s.plans.GetCurrentPlan(ctx, traveller.ID)
	if err != nil {
		return nil, fmt.Errorf("usage service: get current plan: %w", err)
	}

	records, err := s.plans.GetUsage(ctx, plan.ID)
	if err != nil {
		return nil, fmt.Errorf("usage service: get usage: %w", err)
	}

	byCategory := make(map[string]int64)
	var total int64
	for _, r := range records {
		byCategory[r.Category] += r.BytesUsed
		total += r.BytesUsed
	}

	return &UsageSummary{
		PlanID:         plan.ID,
		TotalBytesUsed: total,
		ByCategory:     byCategory,
	}, nil
}
