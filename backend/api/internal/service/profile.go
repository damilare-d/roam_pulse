package service

import (
	"context"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/repository"
)

type ProfileService struct {
	travellers repository.TravellerRepository
}

func NewProfileService(travellers repository.TravellerRepository) *ProfileService {
	return &ProfileService{travellers: travellers}
}

func (s *ProfileService) GetProfile(ctx context.Context) (*domain.TravellerProfile, error) {
	return s.travellers.GetDemoProfile(ctx)
}
