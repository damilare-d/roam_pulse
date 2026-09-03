package service

import (
	"context"
	"fmt"

	"roampulse/backend/internal/repository"
)

type TripService struct {
	travellers   repository.TravellerRepository
	plans        repository.PlanRepository
	destinations repository.DestinationRepository
	networks     repository.NetworkRepository
	connectivity repository.ConnectivityRepository
}

func NewTripService(
	travellers repository.TravellerRepository,
	plans repository.PlanRepository,
	destinations repository.DestinationRepository,
	networks repository.NetworkRepository,
	connectivity repository.ConnectivityRepository,
) *TripService {
	return &TripService{
		travellers:   travellers,
		plans:        plans,
		destinations: destinations,
		networks:     networks,
		connectivity: connectivity,
	}
}

// GetCurrentTrip assembles the traveller's active plan with the
// destination and the network its most recent session connected to — the
// identity view of "where am I and on what network", as opposed to
// PlanService's "what's left on my plan".
func (s *TripService) GetCurrentTrip(ctx context.Context) (*TripSummary, error) {
	traveller, err := s.travellers.GetDemoProfile(ctx)
	if err != nil {
		return nil, fmt.Errorf("trip service: get traveller: %w", err)
	}

	plan, err := s.plans.GetCurrentPlan(ctx, traveller.ID)
	if err != nil {
		return nil, fmt.Errorf("trip service: get current plan: %w", err)
	}

	destination, err := s.destinations.GetByID(ctx, plan.DestinationID)
	if err != nil {
		return nil, fmt.Errorf("trip service: get destination: %w", err)
	}

	session, err := s.connectivity.GetLatestSession(ctx, plan.ID)
	if err != nil {
		return nil, fmt.Errorf("trip service: get latest session: %w", err)
	}

	network, err := s.networks.GetByID(ctx, session.NetworkID)
	if err != nil {
		return nil, fmt.Errorf("trip service: get network: %w", err)
	}

	return &TripSummary{
		Traveller:   *traveller,
		Destination: *destination,
		Network:     *network,
		Plan:        *plan,
	}, nil
}
