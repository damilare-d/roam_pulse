package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type ProfileHandler struct {
	service *service.ProfileService
}

func NewProfileHandler(s *service.ProfileService) *ProfileHandler {
	return &ProfileHandler{service: s}
}

func (h *ProfileHandler) Get(w http.ResponseWriter, r *http.Request) {
	profile, err := h.service.GetProfile(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, profile)
}
