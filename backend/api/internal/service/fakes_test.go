package service_test

import (
	"context"

	"roampulse/backend/internal/domain"
)

type fakeTravellerRepo struct {
	profile *domain.TravellerProfile
	err     error
}

func (f *fakeTravellerRepo) GetDemoProfile(ctx context.Context) (*domain.TravellerProfile, error) {
	return f.profile, f.err
}

type fakePlanRepo struct {
	plan     *domain.TravelPlan
	planErr  error
	usage    []domain.UsageRecord
	usageErr error
}

func (f *fakePlanRepo) GetCurrentPlan(ctx context.Context, travellerID string) (*domain.TravelPlan, error) {
	return f.plan, f.planErr
}

func (f *fakePlanRepo) GetUsage(ctx context.Context, planID string) ([]domain.UsageRecord, error) {
	return f.usage, f.usageErr
}

type fakeDestinationRepo struct {
	destination *domain.Destination
	err         error
}

func (f *fakeDestinationRepo) GetByID(ctx context.Context, id string) (*domain.Destination, error) {
	return f.destination, f.err
}

type fakeNetworkRepo struct {
	network *domain.Network
	err     error
}

func (f *fakeNetworkRepo) GetByID(ctx context.Context, id string) (*domain.Network, error) {
	return f.network, f.err
}

type fakeConnectivityRepo struct {
	session    *domain.NetworkSession
	sessionErr error
	events     []domain.ConnectivityEvent
	eventsErr  error
}

func (f *fakeConnectivityRepo) GetLatestSession(ctx context.Context, planID string) (*domain.NetworkSession, error) {
	return f.session, f.sessionErr
}

func (f *fakeConnectivityRepo) GetRecentEvents(ctx context.Context, planID string, limit int) ([]domain.ConnectivityEvent, error) {
	return f.events, f.eventsErr
}

type fakeEsimRepo struct {
	esim *domain.Esim
	err  error
}

func (f *fakeEsimRepo) GetByID(ctx context.Context, id string) (*domain.Esim, error) {
	return f.esim, f.err
}

type fakeDiagnosticRepo struct {
	session      *domain.DiagnosticSession
	createErr    error
	saveErr      error
	savedResults []domain.DiagnosticResultRecord
}

func (f *fakeDiagnosticRepo) CreateSession(
	ctx context.Context,
	planID string,
	trigger domain.DiagnosticTrigger,
) (*domain.DiagnosticSession, error) {
	if f.createErr != nil {
		return nil, f.createErr
	}
	if f.session != nil {
		return f.session, nil
	}
	return &domain.DiagnosticSession{ID: "session-1", PlanID: planID, Trigger: trigger}, nil
}

func (f *fakeDiagnosticRepo) SaveResult(ctx context.Context, sessionID string, result domain.DiagnosticResultRecord) error {
	if f.saveErr != nil {
		return f.saveErr
	}
	f.savedResults = append(f.savedResults, result)
	return nil
}
