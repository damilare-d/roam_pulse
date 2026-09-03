package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

// Services bundles every application service the router wires to a route.
// Diagnostics, AI, and sync endpoints join this set in Phases 6, 8, and 11.
type Services struct {
	Profile      *service.ProfileService
	Trip         *service.TripService
	Plan         *service.PlanService
	Usage        *service.UsageService
	Connectivity *service.ConnectivityService
	Destination  *service.DestinationService
	Network      *service.NetworkService
}

func NewRouter(services Services) *http.ServeMux {
	mux := http.NewServeMux()

	RegisterHealthRoutes(mux)

	profile := NewProfileHandler(services.Profile)
	mux.HandleFunc("GET /api/v1/profile", profile.Get)

	trip := NewTripHandler(services.Trip)
	mux.HandleFunc("GET /api/v1/trips/current", trip.GetCurrent)

	plan := NewPlanHandler(services.Plan)
	mux.HandleFunc("GET /api/v1/plans/current", plan.GetCurrent)

	usage := NewUsageHandler(services.Usage)
	mux.HandleFunc("GET /api/v1/usage", usage.Get)

	connectivity := NewConnectivityHandler(services.Connectivity)
	mux.HandleFunc("GET /api/v1/connectivity", connectivity.GetStatus)
	mux.HandleFunc("GET /api/v1/connectivity/events", connectivity.GetEvents)

	destination := NewDestinationHandler(services.Destination)
	mux.HandleFunc("GET /api/v1/destinations/{id}", destination.GetByID)

	network := NewNetworkHandler(services.Network)
	mux.HandleFunc("GET /api/v1/networks/{id}", network.GetByID)

	return mux
}
