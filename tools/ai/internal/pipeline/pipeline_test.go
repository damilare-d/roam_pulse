package pipeline_test

import (
	"strings"
	"testing"

	"roampulse/tools/ai/internal/pipeline"
)

func allPassing() []pipeline.GateResult {
	results := make([]pipeline.GateResult, len(pipeline.RequiredGates))
	for i, name := range pipeline.RequiredGates {
		results[i] = pipeline.GateResult{Name: name, Status: pipeline.StatusPassed}
	}
	return results
}

func TestEvaluate_AllGatesPassingIsReady(t *testing.T) {
	verdict := pipeline.Evaluate(allPassing())
	if !verdict.Ready {
		t.Fatalf("expected Ready, got not ready: %s", verdict.Reason)
	}
}

func TestEvaluate_AGateThatNeverRanBlocksTheVerdict(t *testing.T) {
	// Simulates an AI-assisted change that generated code and jumped
	// straight to "done" without ever invoking the tests gate.
	results := allPassing()
	filtered := results[:0]
	for _, r := range results {
		if r.Name != "tests" {
			filtered = append(filtered, r)
		}
	}

	verdict := pipeline.Evaluate(filtered)
	if verdict.Ready {
		t.Fatal("expected not ready when a required gate never ran")
	}
	if !strings.Contains(verdict.Reason, `"tests"`) {
		t.Errorf("reason should name the missing gate, got: %q", verdict.Reason)
	}
}

func TestEvaluate_AFailedGateBlocksTheVerdict(t *testing.T) {
	results := allPassing()
	for i, r := range results {
		if r.Name == "static-analysis" {
			results[i] = pipeline.GateResult{Name: r.Name, Status: pipeline.StatusFailed, Detail: "3 lint errors"}
		}
	}

	verdict := pipeline.Evaluate(results)
	if verdict.Ready {
		t.Fatal("expected not ready when a required gate failed")
	}
	if !strings.Contains(verdict.Reason, "3 lint errors") {
		t.Errorf("reason should surface the failure detail, got: %q", verdict.Reason)
	}
}

func TestEvaluate_ASkippedGateBlocksTheVerdict(t *testing.T) {
	// The core guarantee this package exists for: marking a gate
	// "skipped" is not the same as passing it, and can't be used to sneak
	// an unreviewed or untested change through.
	results := allPassing()
	for i, r := range results {
		if r.Name == "human-review" {
			results[i] = pipeline.GateResult{Name: r.Name, Status: pipeline.StatusSkipped}
		}
	}

	verdict := pipeline.Evaluate(results)
	if verdict.Ready {
		t.Fatal("expected not ready when human review was skipped")
	}
	if !strings.Contains(verdict.Reason, `"human-review"`) {
		t.Errorf("reason should name the skipped gate, got: %q", verdict.Reason)
	}
}

func TestEvaluate_GateOrderInTheInputDoesNotAffectTheVerdict(t *testing.T) {
	results := allPassing()
	// Reverse the slice — Evaluate should still check gates in
	// RequiredGates' canonical order, not input order.
	for i, j := 0, len(results)-1; i < j; i, j = i+1, j-1 {
		results[i], results[j] = results[j], results[i]
	}

	verdict := pipeline.Evaluate(results)
	if !verdict.Ready {
		t.Fatalf("expected Ready regardless of input order, got: %s", verdict.Reason)
	}
}

func TestHumanReviewGate(t *testing.T) {
	tests := []struct {
		name         string
		confirmation string
		wantStatus   pipeline.GateStatus
	}{
		{"empty confirmation is not a pass", "", pipeline.StatusSkipped},
		{"whitespace-only confirmation is not a pass", "   ", pipeline.StatusSkipped},
		{"a real confirmation passes", "Alex reviewed this on the call", pipeline.StatusPassed},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := pipeline.HumanReviewGate(tt.confirmation)
			if result.Status != tt.wantStatus {
				t.Errorf("Status = %q, want %q", result.Status, tt.wantStatus)
			}
		})
	}
}
