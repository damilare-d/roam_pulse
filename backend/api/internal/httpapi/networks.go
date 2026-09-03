package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type NetworkHandler struct {
	service *service.NetworkService
}

func NewNetworkHandler(s *service.NetworkService) *NetworkHandler {
	return &NetworkHandler{service: s}
}

func (h *NetworkHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	network, err := h.service.GetByID(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, network)
}
