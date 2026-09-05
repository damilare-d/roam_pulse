// Package pipeline is the guardrail at the center of RoamPulse's
// AI-assisted engineering workflow (tools/ai/README.md, §18 of the build
// brief): proposal → architecture validation → code generation happen
// interactively between a developer and Claude, exactly as they did for
// every phase of this project. What this package enforces is the part
// that must never be skippable regardless of who (or what) wrote the
// code: formatting, static analysis, tests, coverage, and an explicit
// human review confirmation.
package pipeline

import (
	"fmt"
	"strings"
)

type GateStatus string

const (
	StatusPassed  GateStatus = "passed"
	StatusFailed  GateStatus = "failed"
	StatusSkipped GateStatus = "skipped"
)

type GateResult struct {
	Name   string
	Status GateStatus
	Detail string
}

// RequiredGates is the fixed set every change must clear before it's
// ready for review. A gate that never ran is treated exactly like one
// that failed — "nobody got around to it" is not a passing state.
var RequiredGates = []string{"format", "static-analysis", "tests", "coverage", "human-review"}

type Verdict struct {
	Ready  bool
	Reason string
}

// Evaluate is pure — no I/O, no clock reads — so the guardrail itself
// ("an AI-assisted change can't skip formatting, analysis, tests,
// coverage, or human review") is fully unit-testable without actually
// running any of those tools. Same pure-core pattern as ADR-009's
// diagnostic engine and Chaos Mode's decideChaosAction.
func Evaluate(results []GateResult) Verdict {
	byName := make(map[string]GateResult, len(results))
	for _, r := range results {
		byName[r.Name] = r
	}

	for _, name := range RequiredGates {
		result, ran := byName[name]
		if !ran {
			return Verdict{Ready: false, Reason: fmt.Sprintf("gate %q never ran", name)}
		}
		switch result.Status {
		case StatusPassed:
			continue
		case StatusFailed:
			return Verdict{Ready: false, Reason: fmt.Sprintf("gate %q failed: %s", name, result.Detail)}
		case StatusSkipped:
			return Verdict{Ready: false, Reason: fmt.Sprintf("gate %q was skipped, not run", name)}
		default:
			return Verdict{Ready: false, Reason: fmt.Sprintf("gate %q has an unrecognized status %q", name, result.Status)}
		}
	}

	return Verdict{Ready: true, Reason: "all gates passed"}
}

// HumanReviewGate turns whatever a caller passed as a review
// confirmation into a GateResult. There is no path to a Passed status
// here except a non-empty, human-supplied string — the tool has no way
// to grant this gate on an AI's behalf.
func HumanReviewGate(confirmation string) GateResult {
	trimmed := strings.TrimSpace(confirmation)
	if trimmed == "" {
		return GateResult{
			Name:   "human-review",
			Status: StatusSkipped,
			Detail: "no --reviewer confirmation supplied",
		}
	}
	return GateResult{Name: "human-review", Status: StatusPassed, Detail: trimmed}
}
