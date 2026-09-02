// Package httpapi holds the HTTP layer of the RoamPulse backend.
//
// Phase 1 only registers the health endpoint; the versioned /api/v1 routes
// (profile, plans, connectivity, diagnostics, ai, sync) are added in
// Phase 2 alongside the service/domain/repository layers they depend on —
// see docs/ARCHITECTURE.md.
package httpapi

import (
	"encoding/json"
	"net/http"
)

type healthResponse struct {
	Status string `json:"status"`
}

// RegisterHealthRoutes wires the liveness endpoint onto mux.
func RegisterHealthRoutes(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", handleHealth)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(healthResponse{Status: "ok"})
}
