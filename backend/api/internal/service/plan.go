package service

import (
	"context"
	"fmt"
	"time"

	"roampulse/backend/internal/repository"
)

type PlanService struct {
	travellers repository.TravellerRepository
	plans      repository.PlanRepository
}

func NewPlanService(travellers repository.TravellerRepository, plans repository.PlanRepository) *PlanService {
	return &PlanService{travellers: travellers, plans: plans}
}

const bytesPerMB = 1024 * 1024

// GetCurrentPlanSummary computes data remaining (allowance minus recorded
// usage, clamped at zero) and whole days remaining until expiry — the two
// numbers the dashboard mock in docs/PRODUCT_DISCOVERY.md leads with.
func (s *PlanService) GetCurrentPlanSummary(ctx context.Context) (*PlanSummary, error) {
	traveller, err := s.travellers.GetDemoProfile(ctx)
	if err != nil {
		return nil, fmt.Errorf("plan service: get traveller: %w", err)
	}

	plan, err := s.plans.GetCurrentPlan(ctx, traveller.ID)
	if err != nil {
		return nil, fmt.Errorf("plan service: get current plan: %w", err)
	}

	usage, err := s.plans.GetUsage(ctx, plan.ID)
	if err != nil {
		return nil, fmt.Errorf("plan service: get usage: %w", err)
	}

	var totalBytes int64
	for _, u := range usage {
		totalBytes += u.BytesUsed
	}

	dataUsedMB := float64(totalBytes) / bytesPerMB
	dataAllowanceMB := float64(plan.DataAllowanceMB)
	dataRemainingMB := dataAllowanceMB - dataUsedMB
	if dataRemainingMB < 0 {
		dataRemainingMB = 0
	}

	daysRemaining := int(time.Until(plan.ExpiresAt).Hours() / 24)
	if daysRemaining < 0 {
		daysRemaining = 0
	}

	return &PlanSummary{
		Plan:            *plan,
		DataAllowanceMB: dataAllowanceMB,
		DataUsedMB:      dataUsedMB,
		DataRemainingMB: dataRemainingMB,
		DaysRemaining:   daysRemaining,
	}, nil
}
