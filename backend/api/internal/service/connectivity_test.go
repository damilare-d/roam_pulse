package service_test

import (
	"context"
	"testing"
	"time"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/service"
)

func TestGetStatus_UsesLatestEventForState(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1"}}
	networks := &fakeNetworkRepo{network: &domain.Network{ID: "network-1", CarrierName: "SoftBank"}}

	latency := 42
	eventTime := time.Now()
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{
			NetworkID:      "network-1",
			SignalStrength: "strong",
			LatencyMs:      &latency,
			ConnectedAt:    eventTime.Add(-time.Hour),
		},
		events: []domain.ConnectivityEvent{
			{ToState: domain.ConnectivityDegraded, OccurredAt: eventTime},
		},
	}

	svc := service.NewConnectivityService(travellers, plans, networks, connectivity)
	status, err := svc.GetStatus(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if status.State != domain.ConnectivityDegraded {
		t.Errorf("State = %q, want %q", status.State, domain.ConnectivityDegraded)
	}
	if status.SignalStrength != "strong" {
		t.Errorf("SignalStrength = %q, want %q", status.SignalStrength, "strong")
	}
	if !status.LastEventAt.Equal(eventTime) {
		t.Errorf("LastEventAt = %v, want %v", status.LastEventAt, eventTime)
	}
}

func TestGetStatus_UnknownWhenNoEventsRecorded(t *testing.T) {
	travellers := &fakeTravellerRepo{profile: &domain.TravellerProfile{ID: "traveller-1"}}
	plans := &fakePlanRepo{plan: &domain.TravelPlan{ID: "plan-1"}}
	networks := &fakeNetworkRepo{network: &domain.Network{ID: "network-1"}}
	connectivity := &fakeConnectivityRepo{
		session: &domain.NetworkSession{NetworkID: "network-1", ConnectedAt: time.Now()},
		events:  nil,
	}

	svc := service.NewConnectivityService(travellers, plans, networks, connectivity)
	status, err := svc.GetStatus(context.Background())
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if status.State != domain.ConnectivityUnknown {
		t.Errorf("State = %q, want %q (no events recorded)", status.State, domain.ConnectivityUnknown)
	}
}
