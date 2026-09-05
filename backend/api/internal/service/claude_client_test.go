package service_test

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"

	"roampulse/backend/internal/service"
)

func TestClaudeClient_NoAPIKeyReturnsNotConfiguredWithoutMakingARequest(t *testing.T) {
	client := service.NewClaudeClient("")
	_, err := client.Recommend(context.Background(), "system", "user")
	if err != service.ErrAIClientNotConfigured {
		t.Fatalf("error = %v, want ErrAIClientNotConfigured", err)
	}
}

func TestClaudeClient_Recommend_ParsesToolUseBlock(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if got := r.Header.Get("x-api-key"); got != "test-key" {
			t.Errorf("x-api-key header = %q, want %q", got, "test-key")
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{
			"stop_reason": "tool_use",
			"content": [
				{"type": "text", "text": "Let me check."},
				{"type": "tool_use", "id": "toolu_1", "name": "provide_recovery_recommendation", "input": {"summary": "Weak signal detected.", "steps": ["Move to an open area."], "confidence": 0.7, "escalate": false}}
			]
		}`))
	}))
	defer server.Close()

	client := service.NewClaudeClientForTest("test-key", server.URL)
	payload, err := client.Recommend(context.Background(), "system", "user")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if payload.Summary != "Weak signal detected." {
		t.Errorf("Summary = %q, want %q", payload.Summary, "Weak signal detected.")
	}
	if len(payload.Steps) != 1 || payload.Steps[0] != "Move to an open area." {
		t.Errorf("Steps = %v", payload.Steps)
	}
	if payload.Confidence != 0.7 {
		t.Errorf("Confidence = %v, want 0.7", payload.Confidence)
	}
}

func TestClaudeClient_Recommend_NonOKStatusIsAnError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusTooManyRequests)
		_, _ = w.Write([]byte(`{"error": {"type": "rate_limit_error", "message": "rate limited"}}`))
	}))
	defer server.Close()

	client := service.NewClaudeClientForTest("test-key", server.URL)
	_, err := client.Recommend(context.Background(), "system", "user")
	if err == nil {
		t.Fatal("expected an error for a 429 response")
	}
}

func TestClaudeClient_Recommend_MissingToolUseBlockIsAnError(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"stop_reason": "end_turn", "content": [{"type": "text", "text": "I'm not sure."}]}`))
	}))
	defer server.Close()

	client := service.NewClaudeClientForTest("test-key", server.URL)
	_, err := client.Recommend(context.Background(), "system", "user")
	if err == nil {
		t.Fatal("expected an error when no tool_use block is present")
	}
}
