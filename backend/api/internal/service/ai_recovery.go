package service

import (
	"fmt"
	"strings"
)

// AIRecommendation is the Connectivity Recovery Agent's output — either
// genuinely Claude-generated (Source "ai") or the deterministic engine's
// own recommendation wrapped to the same shape (Source "fallback") when
// Claude is unreachable, misconfigured, or returns something we can't
// validate. The UI always shows which one it got — see ADR-008; a
// silently-degraded answer presented as if it were the real thing is
// exactly the mistake ADR-006 already ruled out for stale cache data.
type AIRecommendation struct {
	Summary    string   `json:"summary"`
	Steps      []string `json:"steps"`
	Confidence float64  `json:"confidence"`
	Escalate   bool     `json:"escalate"`
	Source     string   `json:"source"`
}

// aiRecommendationPayload is the raw shape Claude's tool call returns,
// before it's wrapped into an AIRecommendation with a Source. Kept
// separate from AIRecommendation so a malformed payload can never leak
// out with Source "ai" unset or wrong.
type aiRecommendationPayload struct {
	Summary    string   `json:"summary"`
	Steps      []string `json:"steps"`
	Confidence float64  `json:"confidence"`
	Escalate   bool     `json:"escalate"`
}

const recoveryToolName = "provide_recovery_recommendation"

// recoveryTool is the tool schema Claude is forced to call — pure and
// constant so ai_recovery_test.go and claude_client.go share one
// definition. `strict: true` + `additionalProperties: false` makes the
// API itself guarantee schema-valid output; validateRecommendationPayload
// still checks the value *ranges* schema validation can't express.
func recoveryTool() claudeTool {
	return claudeTool{
		Name:        recoveryToolName,
		Description: "Provide a traveler-friendly connectivity recovery recommendation grounded in the given diagnostic result.",
		Strict:      true,
		InputSchema: map[string]any{
			"type": "object",
			"properties": map[string]any{
				"summary": map[string]any{
					"type":        "string",
					"description": "One or two plain-language sentences summarizing the issue and the fix",
				},
				"steps": map[string]any{
					"type":        "array",
					"items":       map[string]any{"type": "string"},
					"description": "1 to 4 ordered, concrete steps the traveler can take themselves",
				},
				"confidence": map[string]any{
					"type":        "number",
					"description": "0 to 1",
				},
				"escalate": map[string]any{
					"type":        "boolean",
					"description": "true only if self-service steps are unlikely to fix this (e.g. plan/eSIM/account issues), not for a simple weak-signal case",
				},
			},
			"required":             []string{"summary", "steps", "confidence", "escalate"},
			"additionalProperties": false,
		},
	}
}

// buildRecoveryPrompt is pure — no I/O, no clock reads — so it's
// unit-testable the same way Diagnose (ADR-009) and decideChaosAction
// (Chaos Mode) are: given a Diagnosis, what prompt would we send.
func buildRecoveryPrompt(d Diagnosis) (system, user string) {
	system = "You are RoamPulse's connectivity recovery assistant, helping a traveler abroad understand and fix an eSIM/network issue. " +
		"Ground every claim in the diagnostic data given to you — never invent facts about the traveler's account, plan, location, or device beyond what's provided. " +
		"Keep the summary to one or two plain-language sentences. Give 1 to 4 concrete, ordered steps a traveler can take themselves. " +
		"If the diagnosis is already healthy, reassure them briefly instead of inventing a problem."

	checks := make([]string, len(d.Checks))
	for i, c := range d.Checks {
		status := "passed"
		if !c.Passed {
			status = "failed"
		}
		checks[i] = fmt.Sprintf("- %s: %s", c.Label, status)
	}

	user = fmt.Sprintf(
		"Diagnostic result:\nIssue: %s\nSeverity: %s\nConfidence: %.2f\nDeterministic recommendation: %s\nChecks:\n%s\n\nProvide a traveler-friendly recommendation via the %s tool.",
		d.Issue, d.Severity, d.Confidence, d.Recommendation, strings.Join(checks, "\n"), recoveryToolName,
	)
	return system, user
}

// validateRecommendationPayload checks the value ranges that
// `input_schema` + `strict: true` can't express on their own (an empty
// string, an out-of-range confidence, more steps than the prompt asked
// for). A payload that fails this is treated exactly like a network
// error — the caller falls back to the deterministic recommendation
// rather than showing something we can't stand behind.
func validateRecommendationPayload(p aiRecommendationPayload) error {
	if strings.TrimSpace(p.Summary) == "" {
		return fmt.Errorf("summary is empty")
	}
	if len(p.Steps) == 0 || len(p.Steps) > 4 {
		return fmt.Errorf("steps must have 1-4 items, got %d", len(p.Steps))
	}
	for i, step := range p.Steps {
		if strings.TrimSpace(step) == "" {
			return fmt.Errorf("step %d is empty", i)
		}
	}
	if p.Confidence < 0 || p.Confidence > 1 {
		return fmt.Errorf("confidence %.2f out of range [0,1]", p.Confidence)
	}
	return nil
}

// fallbackRecommendation wraps the deterministic diagnosis's own
// recommendation to the same AIRecommendation shape the UI renders,
// tagged Source "fallback" so it's never mistaken for a real AI answer.
// Escalate mirrors the deterministic severity rather than guessing.
func fallbackRecommendation(d Diagnosis) AIRecommendation {
	return AIRecommendation{
		Summary:    d.Issue,
		Steps:      []string{d.Recommendation},
		Confidence: d.Confidence,
		Escalate:   d.Severity == "high",
		Source:     "fallback",
	}
}
