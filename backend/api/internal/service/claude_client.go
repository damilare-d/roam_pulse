package service

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

const (
	claudeAPIURL     = "https://api.anthropic.com/v1/messages"
	claudeAPIVersion = "2023-06-01"
	// claudeModel is Anthropic's current recommended default — see
	// docs/decisions/ADR-008-claude-recovery-agent.md for why this isn't
	// swapped for a cheaper tier without an explicit ask.
	claudeModel = "claude-opus-5"
)

// ErrAIClientNotConfigured means ANTHROPIC_API_KEY is unset — a normal,
// expected state (e.g. no key provisioned yet), not a bug. AIRecoveryService
// treats it exactly like any other AIClient error: fall back, don't fail
// the request.
var ErrAIClientNotConfigured = errors.New("claude client: ANTHROPIC_API_KEY not configured")

// AIClient is the port to a Claude-backed recommendation model. The one
// production implementation, ClaudeClient, is a thin I/O shell — request
// construction (buildRecoveryPrompt, recoveryTool) and response validation
// (validateRecommendationPayload) are pure functions in ai_recovery.go, so
// only the actual HTTP round-trip needs a fake server to test (same
// pure-core/thin-shell split as ADR-009's diagnostic engine and Chaos
// Mode's decideChaosAction).
type AIClient interface {
	Recommend(ctx context.Context, system, user string) (aiRecommendationPayload, error)
}

type ClaudeClient struct {
	apiKey     string
	httpClient *http.Client
	baseURL    string
}

func NewClaudeClient(apiKey string) *ClaudeClient {
	return &ClaudeClient{
		apiKey:     apiKey,
		httpClient: &http.Client{Timeout: 20 * time.Second},
		baseURL:    claudeAPIURL,
	}
}

type claudeTool struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	InputSchema any    `json:"input_schema"`
	Strict      bool   `json:"strict"`
}

type claudeMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type claudeRequest struct {
	Model        string            `json:"model"`
	MaxTokens    int               `json:"max_tokens"`
	System       string            `json:"system"`
	Messages     []claudeMessage   `json:"messages"`
	Tools        []claudeTool      `json:"tools"`
	ToolChoice   map[string]string `json:"tool_choice"`
	Thinking     map[string]string `json:"thinking"`
	OutputConfig map[string]string `json:"output_config"`
}

type claudeContentBlock struct {
	Type  string          `json:"type"`
	Name  string          `json:"name,omitempty"`
	Input json.RawMessage `json:"input,omitempty"`
}

type claudeResponse struct {
	StopReason string               `json:"stop_reason"`
	Content    []claudeContentBlock `json:"content"`
}

type claudeErrorResponse struct {
	Error struct {
		Type    string `json:"type"`
		Message string `json:"message"`
	} `json:"error"`
}

// Recommend forces Claude to call recoveryTool and returns its parsed
// input. max_tokens is deliberately small (1024) — the output shape is a
// short, bounded structured payload, not open-ended generation. Effort is
// "low" with adaptive thinking left on rather than disabled, since
// disabling thinking on this model can make it write a tool call into
// visible text instead of a proper tool_use block — a needless footgun
// for a task this simple.
func (c *ClaudeClient) Recommend(ctx context.Context, system, user string) (aiRecommendationPayload, error) {
	if c.apiKey == "" {
		return aiRecommendationPayload{}, ErrAIClientNotConfigured
	}

	tool := recoveryTool()
	reqBody := claudeRequest{
		Model:        claudeModel,
		MaxTokens:    1024,
		System:       system,
		Messages:     []claudeMessage{{Role: "user", Content: user}},
		Tools:        []claudeTool{tool},
		ToolChoice:   map[string]string{"type": "tool", "name": tool.Name},
		Thinking:     map[string]string{"type": "adaptive"},
		OutputConfig: map[string]string{"effort": "low"},
	}

	body, err := json.Marshal(reqBody)
	if err != nil {
		return aiRecommendationPayload{}, fmt.Errorf("claude client: marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL, bytes.NewReader(body))
	if err != nil {
		return aiRecommendationPayload{}, fmt.Errorf("claude client: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", c.apiKey)
	req.Header.Set("anthropic-version", claudeAPIVersion)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return aiRecommendationPayload{}, fmt.Errorf("claude client: request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return aiRecommendationPayload{}, fmt.Errorf("claude client: read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		var apiErr claudeErrorResponse
		_ = json.Unmarshal(respBody, &apiErr)
		return aiRecommendationPayload{}, fmt.Errorf("claude client: API returned %d: %s", resp.StatusCode, apiErr.Error.Message)
	}

	var parsed claudeResponse
	if err := json.Unmarshal(respBody, &parsed); err != nil {
		return aiRecommendationPayload{}, fmt.Errorf("claude client: decode response: %w", err)
	}

	for _, block := range parsed.Content {
		if block.Type == "tool_use" && block.Name == tool.Name {
			var payload aiRecommendationPayload
			if err := json.Unmarshal(block.Input, &payload); err != nil {
				return aiRecommendationPayload{}, fmt.Errorf("claude client: decode tool input: %w", err)
			}
			return payload, nil
		}
	}

	return aiRecommendationPayload{}, fmt.Errorf("claude client: no %s tool_use block in response (stop_reason=%s)", tool.Name, parsed.StopReason)
}
