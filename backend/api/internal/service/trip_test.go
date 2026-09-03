package service_test

import (
	"context"
	"testing"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestGetCurrentTrip_ComposesAcrossRepositories(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1", DisplayName: "Alex"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1", DestinationID: "dest-1"}}
	destinations := &fakeDestinationRepo{destination: &domain.Destination{ID: "dest-1", City: "Tokyo"}}
	networks := &fakeNetworkRepo{network: &domain.Network{ID: "network-1", CarrierName: "SoftBank"}}
	connectivity := &fakeConnectivityRepo{session: &domain.NetworkSession{NetworkID: "network-1"}}

	svc := service.NewTripService(travellers, plans, destinations, networks, connectivity)
	trip, err := svc.GetCurrentTrip(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if trip.Traveller.DisplayName != "Alex" {
		t.Errorf("Traveller.DisplayName = %q, want %q", trip.Traveller.DisplayName, "Alex")
	}
	if trip.Destination.City != "Tokyo" {
		t.Errorf("Destination.City = %q, want %q", trip.Destination.City, "Tokyo")
	}
	if trip.Network.CarrierName != "SoftBank" {
		t.Errorf("Network.CarrierName = %q, want %q", trip.Network.CarrierName, "SoftBank")
	}
}
