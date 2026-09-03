package service

import (
	"context"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/repository"
)

// DestinationService and NetworkService are thin lookups today, but keep
// the same handler -> service -> repository shape as every other service
// so the layering stays consistent rather than special-cased.

type DestinationService struct {
	destinations repository.DestinationRepository
}

func NewDestinationService(destinations repository.DestinationRepository) *DestinationService {
	return &DestinationService{destinations: destinations}
}

func (s *DestinationService) GetByID(ctx context.Context, id string) (*domain.Destination, error) {
	return s.destinations.GetByID(ctx, id)
}

type NetworkService struct {
	networks repository.NetworkRepository
}

func NewNetworkService(networks repository.NetworkRepository) *NetworkService {
	return &NetworkService{networks: networks}
}

func (s *NetworkService) GetByID(ctx context.Context, id string) (*domain.Network, error) {
	return s.networks.GetByID(ctx, id)
}
