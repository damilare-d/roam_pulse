package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type DiagnosticsHandler struct {
	service *service.DiagnosticService
}

func NewDiagnosticsHandler(s *service.DiagnosticService) *DiagnosticsHandler {
	return &DiagnosticsHandler{service: s}
}

func (h *DiagnosticsHandler) Run(w http.ResponseWriter, r *http.Request) {
	diagnosis, err := h.service.RunDiagnostics(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, diagnosis)
}
