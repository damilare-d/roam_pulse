package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type UsageHandler struct {
	service *service.UsageService
}

func NewUsageHandler(s *service.UsageService) *UsageHandler {
	return &UsageHandler{service: s}
}

func (h *UsageHandler) Get(w http.ResponseWriter, r *http.Request) {
	summary, err := h.service.GetUsageSummary(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, summary)
}
