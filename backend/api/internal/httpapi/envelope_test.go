package httpapi

import (
	"encoding/json"
	"errors"
	"net/http/httptest"
	"testing"

	"roampulse/backend/internal/apperror"
)

func TestWriteData_WrapsInEnvelopeWithSyncedAt(t *testing.T) {
	rec := httptest.NewRecorder()
	writeData(rec, 200, map[string]string{"hello": "world"})

	var body successEnvelope
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if body.Meta["syncedAt"] == nil || body.Meta["syncedAt"] == "" {
		t.Errorf("expected meta.syncedAt to be set, got %v", body.Meta)
	}
}

func TestWriteError_ClassifiedErrorUsesItsStatusAndCode(t *testing.T) {
	rec := httptest.NewRecorder()
	writeError(rec, apperror.NotFound("destination not found"))

	if rec.Code != 404 {
		t.Errorf("status = %d, want 404", rec.Code)
	}

	var body errorEnvelope
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body.Error.Code != string(apperror.CodeNotFound) {
		t.Errorf("error.code = %q, want %q", body.Error.Code, apperror.CodeNotFound)
	}
}

func TestWriteError_UnclassifiedErrorFallsBackToInternal(t *testing.T) {
	rec := httptest.NewRecorder()
	writeError(rec, errors.New("something exploded deep in a driver"))

	if rec.Code != 500 {
		t.Errorf("status = %d, want 500", rec.Code)
	}

	var body errorEnvelope
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body.Error.Code != string(apperror.CodeInternal) {
		t.Errorf("error.code = %q, want %q", body.Error.Code, apperror.CodeInternal)
	}
	// The raw internal error text must never leak to the client.
	if body.Error.Message == "something exploded deep in a driver" {
		t.Errorf("internal error detail leaked to client response: %q", body.Error.Message)
	}
}
