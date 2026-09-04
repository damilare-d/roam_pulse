package service_test

import (
	"context"
	"errors"
	"testing"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestSignInDemo_ReturnsTokenWhenDemoTravellerExists(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}

	svc := service.NewAuthService(travellers)
	session, err := svc.SignInDemo(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if session.SessionToken == "" {
		t.Error("expected a non-empty session token")
	}
}

func TestSignInDemo_PropagatesRepositoryError(t *testing.T) {
	wantErr := errors.New("no demo traveller seeded")
	travellers := &fakeTravellerRepo{err: wantErr}

	svc := service.NewAuthService(travellers)
	_, err := svc.SignInDemo(context.Background())
	if !errors.Is(err, wantErr) {
		t.Fatalf("expected error to wrap %v, got %v", wantErr, err)
	}
}
