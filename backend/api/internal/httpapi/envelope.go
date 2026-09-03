package httpapi

import (
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"time"

	"roampulse/backend/internal/apperror"
)

type successEnvelope struct {
	Data any            `json:"data"`
	Meta map[string]any `json:"meta,omitempty"`
}

type errorEnvelope struct {
	Error errorBody `json:"error"`
}

type errorBody struct {
	Code    string         `json:"code"`
	Message string         `json:"message"`
	Details map[string]any `json:"details,omitempty"`
}

// writeData wraps every successful response in the {data, meta} envelope
// from docs/ARCHITECTURE.md, stamping syncedAt so clients always know when
// this response was produced — never let cached data look identical to
// fresh data (product principle in docs/PRODUCT_DISCOVERY.md).
func writeData(w http.ResponseWriter, status int, data any) {
	writeJSON(w, status, successEnvelope{
		Data: data,
		Meta: map[string]any{"syncedAt": time.Now().UTC().Format(time.RFC3339)},
	})
}

// writeError classifies err into the {error: {code, message, details}}
// envelope. Unclassified errors never leak internal detail to the client —
// they're logged server-side and returned as a generic internal error.
func writeError(w http.ResponseWriter, err error) {
	var appErr *apperror.Error
	if errors.As(err, &appErr) {
		writeJSON(w, appErr.HTTPStatus(), errorEnvelope{Error: errorBody{
			Code:    string(appErr.Code),
			Message: appErr.Message,
			Details: appErr.Details,
		}})
		return
	}

	log.Printf("httpapi: unclassified error: %v", err)
	writeJSON(w, http.StatusInternalServerError, errorEnvelope{Error: errorBody{
		Code:    string(apperror.CodeInternal),
		Message: "an unexpected error occurred",
	}})
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Printf("httpapi: failed to encode response: %v", err)
	}
}
