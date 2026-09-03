package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type DestinationHandler struct {
	service *service.DestinationService
}

func NewDestinationHandler(s *service.DestinationService) *DestinationHandler {
	return &DestinationHandler{service: s}
}

func (h *DestinationHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	destination, err := h.service.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, destination)
}
