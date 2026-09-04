package httpapi

import (
	"net/http"

	"roampulse/backend/internal/service"
)

type AuthHandler struct {
	service *service.AuthService
}

func NewAuthHandler(s *service.AuthService) *AuthHandler {
	return &AuthHandler{service: s}
}

type demoSessionResponse struct {
	SessionToken string `json:"sessionToken"`
}

func (h *AuthHandler) SignInDemo(w http.ResponseWriter, r *http.Request) {
	session, err := h.service.SignInDemo(r.Context())
	if err != nil {
		writeError(w, err)
		return
	}
	writeData(w, http.StatusOK, demoSessionResponse{SessionToken: session.SessionToken})
}
