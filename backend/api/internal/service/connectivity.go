package service

import (
	"context"
	"fmt"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/repository"
)

type ConnectivityService struct {
	travellers   repository.TravellerRepository
	plans        repository.PlanRepository
	networks     repository.NetworkRepository
	connectivity repository.ConnectivityRepository
}

func NewConnectivityService(
	travellers repository.TravellerRepository,
	plans repository.PlanRepository,
	networks repository.NetworkRepository,
	connectivity repository.ConnectivityRepository,
) *ConnectivityService {
	return &ConnectivityService{travellers: travellers, plans: plans, networks: networks, connectivity: connectivity}
}

func (s *ConnectivityService) currentPlanID(ctx context.Context) (string, error) {
	traveller, err := s.travellers.GetDemoProfile(ctx)
	if err != nil {
		return "", fmt.Errorf("connectivity service: get traveller: %w", err)
	}
	plan, err := s.plans.GetCurrentPlan(ctx, traveller.ID)
	if err != nil {
		return "", fmt.Errorf("connectivity service: get current plan: %w", err)
	}
	return plan.ID, nil
}

// GetStatus derives connectivity state from the latest event's to_state
// and connection quality (signal, latency) from the latest session — the
// event stream is the source of truth for *state*, the session for
// *quality*. If no event has ever been recorded, state is Unknown rather
// than guessed.
func (s *ConnectivityService) GetStatus(ctx context.Context) (*ConnectivityStatus, error) {
	planID, err := s.currentPlanID(ctx)
	if err != nil {
		return nil, err
	}

	session, err := s.connectivity.GetLatestSession(ctx, planID)
	if err != nil {
		return nil, fmt.Errorf("connectivity service: get latest session: %w", err)
	}

	network, err := s.networks.GetByID(ctx, session.NetworkID)
	if err != nil {
		return nil, fmt.Errorf("connectivity service: get network: %w", err)
	}

	events, err := s.connectivity.GetRecentEvents(ctx, planID, 1)
	if err != nil {
		return nil, fmt.Errorf("connectivity service: get recent events: %w", err)
	}

	state := domain.ConnectivityUnknown
	lastEventAt := session.ConnectedAt
	if len(events) > 0 {
		state = events[0].ToState
		lastEventAt = events[0].OccurredAt
	}

	return &ConnectivityStatus{
		State:          state,
		Network:        *network,
		SignalStrength: session.SignalStrength,
		LatencyMs:      session.LatencyMs,
		LastEventAt:    lastEventAt,
	}, nil
}

func (s *ConnectivityService) GetEvents(ctx context.Context, limit int) ([]domain.ConnectivityEvent, error) {
	planID, err := s.currentPlanID(ctx)
	if err != nil {
		return nil, err
	}
	return s.connectivity.GetRecentEvents(ctx, planID, limit)
}
