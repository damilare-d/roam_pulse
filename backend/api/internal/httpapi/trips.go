package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type TripHandler struct {
	service *service.TripService
}

func NewTripHandler(s *service.TripService) *TripHandler {
	return &TripHandler{service: s}
}

func (h *TripHandler) GetCurrent(w http.ResponseWriter, r *http.Request) {
	trip, err := h.service.GetCurrentTrip(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, trip)
}
