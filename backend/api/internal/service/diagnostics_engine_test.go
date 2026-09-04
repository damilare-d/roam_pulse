package service_test

import (
	"testing"

	"roampulse/backend/internal/service"
)

func baseInput() service.DiagnosticInput {
	return service.DiagnosticInput{
		PlanActive:        true,
		EsimActive:        true,
		NetworkRegistered: true,
		SignalStrength:    "strong",
		LatencyMs:         intPtr(42),
	}
}

func intPtr(v int) *int { return &v }

func TestDiagnose_HealthyConnectionReportsNoIssues(t *testing.T) {
	diagnosis := service.Diagnose(baseInput())

	if diagnosis.Issue != "Everything looks good" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Everything looks good")
	}
	if diagnosis.Severity != "low" {
		t.Errorf("Severity = %q, want %q", diagnosis.Severity, "low")
	}
	for _, c := range diagnosis.Checks {
		if !c.Passed {
			t.Errorf("expected all checks to pass, %q failed", c.Label)
		}
	}
}

func TestDiagnose_PlanNotActiveTakesPriorityOverEverythingElse(t *testing.T) {
	input := baseInput()
	input.PlanActive = false
	input.EsimActive = false // would also fail, but plan check must win

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "Plan not active" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Plan not active")
	}
	if diagnosis.Severity != "high" {
		t.Errorf("Severity = %q, want %q", diagnosis.Severity, "high")
	}
	if diagnosis.Checks[0].Passed {
		t.Error("expected the plan-active check to be marked failed")
	}
}

func TestDiagnose_EsimNotActiveWhenPlanIsFine(t *testing.T) {
	input := baseInput()
	input.EsimActive = false

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "eSIM not active" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "eSIM not active")
	}
}

func TestDiagnose_NetworkUnavailableMatchesBriefExample(t *testing.T) {
	input := baseInput()
	input.NetworkRegistered = false

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "Network unavailable" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Network unavailable")
	}
	if diagnosis.Severity != "high" {
		t.Errorf("Severity = %q, want %q", diagnosis.Severity, "high")
	}

	// Plan active / eSIM active should still show as passed (✓), only the
	// network check should be marked failed (⚠) — this is the exact
	// pattern from docs/PRODUCT_DISCOVERY.md section 14's example.
	for _, c := range diagnosis.Checks {
		wantPass := c.Label != "Network registered"
		if c.Passed != wantPass {
			t.Errorf("check %q: Passed = %v, want %v", c.Label, c.Passed, wantPass)
		}
	}
}

func TestDiagnose_NoSignal(t *testing.T) {
	input := baseInput()
	input.SignalStrength = "none"

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "No signal" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "No signal")
	}
}

func TestDiagnose_WeakSignalIsDegradedNotCritical(t *testing.T) {
	input := baseInput()
	input.SignalStrength = "weak"

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "Degraded connection" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Degraded connection")
	}
	if diagnosis.Severity != "medium" {
		t.Errorf("Severity = %q, want %q", diagnosis.Severity, "medium")
	}
}

func TestDiagnose_HighLatencyIsDegradedEvenWithStrongSignal(t *testing.T) {
	input := baseInput()
	input.LatencyMs = intPtr(320)

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "Degraded connection" {
		t.Errorf("Issue = %q, want %q", diagnosis.Issue, "Degraded connection")
	}
}

func TestDiagnose_NilLatencyIsNotTreatedAsHighLatency(t *testing.T) {
	input := baseInput()
	input.LatencyMs = nil

	diagnosis := service.Diagnose(input)

	if diagnosis.Issue != "Everything looks good" {
		t.Errorf("Issue = %q, want %q (nil latency shouldn't itself be a problem)", diagnosis.Issue, "Everything looks good")
	}
}

func TestDiagnose_ConfidenceIsAlwaysWithinValidRange(t *testing.T) {
	cases := []service.DiagnosticInput{
		baseInput(),
		func() service.DiagnosticInput { i := baseInput(); i.PlanActive = false; return i }(),
		func() service.DiagnosticInput { i := baseInput(); i.EsimActive = false; return i }(),
		func() service.DiagnosticInput { i := baseInput(); i.NetworkRegistered = false; return i }(),
		func() service.DiagnosticInput { i := baseInput(); i.SignalStrength = "none"; return i }(),
		func() service.DiagnosticInput { i := baseInput(); i.SignalStrength = "weak"; return i }(),
	}

	for _, input := range cases {
		diagnosis := service.Diagnose(input)
		if diagnosis.Confidence < 0 || diagnosis.Confidence > 1 {
			t.Errorf("Confidence = %v for issue %q, want a value in [0, 1]", diagnosis.Confidence, diagnosis.Issue)
		}
	}
}
