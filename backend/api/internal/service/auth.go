package service

import (
	"context"
	"fmt"

	"roampulse/backend/internal/repository"
)

type DemoSession struct {
	SessionToken string
}

// demoSessionToken is a fixed placeholder, not a real credential — demo
// mode has nothing to authenticate against. It exists so the client-side
// AuthRepository has something to store and check, exercising the exact
// contract a JwtAuthDataSource fills with a real token later (see
// ADR-010) without RoamPulse prematurely implementing JWT issuance.
const demoSessionToken = "demo-session-token"

// AuthService issues demo sessions today. A JWT-backed implementation
// replaces SignInDemo's body — not its signature — once real auth lands.
type AuthService struct {
	travellers repository.TravellerRepository
}

func NewAuthService(travellers repository.TravellerRepository) *AuthService {
	return &AuthService{travellers: travellers}
}

func (s *AuthService) SignInDemo(ctx context.Context) (*DemoSession, error) {
	if _, err := s.travellers.GetDemoProfile(ctx); err != nil {
		return nil, fmt.Errorf("auth service: verify demo traveller exists: %w", err)
	}
	return &DemoSession{SessionToken: demoSessionToken}, nil
}
