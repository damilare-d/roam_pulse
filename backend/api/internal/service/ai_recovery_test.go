package service_test

import (
	"strings"
	"testing"

	"roampulse/backend/internal/service"
)

func TestFallbackRecommendation_WrapsDeterministicDiagnosis(t *testing.T) {
	tests := []struct {
		name         string
		severity     string
		wantEscalate bool
	}{
		{"high severity escalates", "high", true},
		{"medium severity does not escalate", "medium", false},
		{"low severity does not escalate", "low", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			rec := service.RecommendationFromDiagnosisForTest(service.Diagnosis{
				Issue:          "No signal",
				Confidence:     0.85,
				Severity:       tt.severity,
				Recommendation: "Move to an open area.",
			})

			if rec.Source != "fallback" {
				t.Errorf("Source = %q, want %q", rec.Source, "fallback")
			}
			if rec.Summary != "No signal" {
				t.Errorf("Summary = %q, want the diagnosis issue", rec.Summary)
			}
			if len(rec.Steps) != 1 || rec.Steps[0] != "Move to an open area." {
				t.Errorf("Steps = %v, want a single step wrapping the deterministic recommendation", rec.Steps)
			}
			if rec.Confidence != 0.85 {
				t.Errorf("Confidence = %v, want 0.85", rec.Confidence)
			}
			if rec.Escalate != tt.wantEscalate {
				t.Errorf("Escalate = %v, want %v for severity %q", rec.Escalate, tt.wantEscalate, tt.severity)
			}
		})
	}
}

func TestBuildRecoveryPrompt_GroundsInTheDiagnosis(t *testing.T) {
	d := service.Diagnosis{
		Issue:          "Degraded connection",
		Confidence:     0.7,
		Severity:       "medium",
		Recommendation: "Your connection is weak.",
		Checks: []service.DiagnosticCheck{
			{Label: "Plan active", Passed: true},
			{Label: "Signal strength", Passed: false},
		},
	}

	system, user := service.BuildRecoveryPromptForTest(d)

	if !strings.Contains(system, "never invent facts") {
		t.Errorf("system prompt should instruct the model to stay grounded, got: %q", system)
	}
	for _, want := range []string{"Degraded connection", "medium", "0.70", "Your connection is weak.", "Plan active: passed", "Signal strength: failed"} {
		if !strings.Contains(user, want) {
			t.Errorf("user prompt missing %q, got: %q", want, user)
		}
	}
}

func TestValidateRecommendationPayload(t *testing.T) {
	tests := []struct {
		name    string
		payload service.AIRecommendationPayloadForTest
		wantErr bool
	}{
		{
			name:    "valid payload",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: []string{"Do nothing"}, Confidence: 0.9},
			wantErr: false,
		},
		{
			name:    "empty summary",
			payload: service.AIRecommendationPayloadForTest{Summary: "  ", Steps: []string{"Do nothing"}, Confidence: 0.9},
			wantErr: true,
		},
		{
			name:    "no steps",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: nil, Confidence: 0.9},
			wantErr: true,
		},
		{
			name:    "too many steps",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: []string{"1", "2", "3", "4", "5"}, Confidence: 0.9},
			wantErr: true,
		},
		{
			name:    "blank step",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: []string{"  "}, Confidence: 0.9},
			wantErr: true,
		},
		{
			name:    "confidence too high",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: []string{"Do nothing"}, Confidence: 1.5},
			wantErr: true,
		},
		{
			name:    "confidence negative",
			payload: service.AIRecommendationPayloadForTest{Summary: "All good", Steps: []string{"Do nothing"}, Confidence: -0.1},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := service.ValidateRecommendationPayloadForTest(tt.payload)
			if (err != nil) != tt.wantErr {
				t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
