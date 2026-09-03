package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type PlanHandler struct {
	service *service.PlanService
}

func NewPlanHandler(s *service.PlanService) *PlanHandler {
	return &PlanHandler{service: s}
}

func (h *PlanHandler) GetCurrent(w http.ResponseWriter, r *http.Request) {
	summary, err := h.service.GetCurrentPlanSummary(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, summary)
}
