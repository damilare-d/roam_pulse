package service

import (
	"net/http"
	"time"
)

// Test-only exports so ai_recovery_test.go / claude_client_test.go (in the
// external service_test package, matching this package's existing test
// convention) can exercise unexported internals directly without widening
// the real public API. Only compiled during `go test` — never in the
// production binary.
type AIRecommendationPayloadForTest = aiRecommendationPayload

var (
	BuildRecoveryPromptForTest           = buildRecoveryPrompt
	ValidateRecommendationPayloadForTest = validateRecommendationPayload
	RecommendationFromDiagnosisForTest   = fallbackRecommendation
)

// NewClaudeClientForTest points a ClaudeClient at a fake server
// (httptest.Server) instead of the real Anthropic API.
func NewClaudeClientForTest(apiKey, baseURL string) *ClaudeClient {
	return &ClaudeClient{
		apiKey:     apiKey,
		httpClient: &http.Client{Timeout: 5 * time.Second},
		baseURL:    baseURL,
	}
}
