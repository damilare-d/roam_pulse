package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type AIRecoveryHandler struct {
	service *service.AIRecoveryService
}

func NewAIRecoveryHandler(s *service.AIRecoveryService) *AIRecoveryHandler {
	return &AIRecoveryHandler{service: s}
}

func (h *AIRecoveryHandler) Recommend(w http.ResponseWriter, r *http.Request) {
	recommendation, err := h.service.GetRecommendation(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, recommendation)
}
