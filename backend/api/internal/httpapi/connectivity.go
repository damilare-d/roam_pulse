package httpapi

import (
	"net/http"
	"strconv"

	"roampulse/backend/internal/service"
)

const defaultEventsLimit = 20

type ConnectivityHandler struct {
	service *service.ConnectivityService
}

func NewConnectivityHandler(s *service.ConnectivityService) *ConnectivityHandler {
	return &ConnectivityHandler{service: s}
}

func (h *ConnectivityHandler) GetStatus(w http.ResponseWriter, r *http.Request) {
	status, err := h.service.GetStatus(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, status)
}

func (h *ConnectivityHandler) GetEvents(w http.ResponseWriter, r *http.Request) {
	limit := defaultEventsLimit
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			limit = parsed
		}
	}

	events, err := h.service.GetEvents(r.Context(), limit)
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, events)
}
