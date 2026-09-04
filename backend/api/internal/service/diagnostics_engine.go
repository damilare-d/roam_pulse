package service

// highLatencyThresholdMs is the one numeric judgment call this engine
// makes — chosen against RoamPulse's own seed data (Tokyo 42ms/healthy,
// Rome 110ms/moderate, Paris 320ms/degraded), not an arbitrary round
// number.
//
// An earlier version of this engine also flagged staleness based on the
// latest connectivity event's age, using the brief's illustrative
// "lastSync" input. That was wrong: a connectivity event only fires on a
// *state transition*, so a connection that's been stably "connected" for
// two days with nothing going wrong has an old event timestamp for a good
// reason, not a stale one — the rule flagged RoamPulse's flagship healthy
// scenario as "out of date" purely because nothing had gone wrong
// recently. Removed rather than kept for brief-completeness; a real
// "is this diagnosis based on fresh data" concern belongs to the caching
// layer (ADR-006), not this rule set.
const highLatencyThresholdMs = 200

// DiagnosticInput is what Diagnose reasons over. It's deliberately a
// smaller, concretely-observable set than the brief's illustrative
// (internetAvailable, esimActive, planActive, networkRegistered,
// signalStrength, networkLatency, lastSync, networkAvailability) — several
// of those collapse to the same thing in RoamPulse's simulated model
// (e.g. "internet available" and "network availability" are both just
// NetworkRegistered/SignalStrength here); this is what the schema can
// genuinely produce, not a padded list.
type DiagnosticInput struct {
	PlanActive        bool
	EsimActive        bool
	NetworkRegistered bool
	SignalStrength    string
	LatencyMs         *int
}

type DiagnosticCheck struct {
	Label  string `json:"label"`
	Passed bool   `json:"passed"`
}

type Diagnosis struct {
	Issue          string            `json:"issue"`
	Confidence     float64           `json:"confidence"`
	Severity       string            `json:"severity"`
	Checks         []DiagnosticCheck `json:"checks"`
	Recommendation string            `json:"recommendation"`
}

// Diagnose is pure and deterministic on purpose — no I/O, no clock reads
// — so it's fully unit-testable and never depends on Claude being
// reachable (ADR-009: deterministic diagnostics before AI). Checks are
// evaluated in priority order; the first failing check determines the
// issue, matching docs/PRODUCT_DISCOVERY.md section 14's example exactly
// (earlier checks show as passed even when a later one fails).
func Diagnose(input DiagnosticInput) Diagnosis {
	checks := []DiagnosticCheck{
		{Label: "Plan active", Passed: input.PlanActive},
		{Label: "eSIM active", Passed: input.EsimActive},
		{Label: "Network registered", Passed: input.NetworkRegistered},
		{Label: "Signal strength", Passed: hasUsableSignal(input.SignalStrength)},
	}

	switch {
	case !input.PlanActive:
		return diagnosis(checks, "Plan not active", 0.95, "high",
			"Your travel plan isn't active — check its status or renew it.")
	case !input.EsimActive:
		return diagnosis(checks, "eSIM not active", 0.95, "high",
			"Your eSIM isn't active — reactivate it in your device settings.")
	case !input.NetworkRegistered:
		return diagnosis(checks, "Network unavailable", 0.9, "high",
			"Your device isn't registered on a network — try toggling Airplane Mode.")
	case input.SignalStrength == "none":
		return diagnosis(checks, "No signal", 0.85, "high",
			"There's no signal at your current location — try moving to an open area.")
	case input.SignalStrength == "weak" || isHighLatency(input.LatencyMs):
		return diagnosis(checks, "Degraded connection", 0.7, "medium",
			"Your connection is weak — some services may be slow to load.")
	default:
		return diagnosis(checks, "Everything looks good", 0.95, "low",
			"No issues detected with your connection.")
	}
}

func hasUsableSignal(signalStrength string) bool {
	return signalStrength != "" && signalStrength != "none" && signalStrength != "weak"
}

func isHighLatency(latencyMs *int) bool {
	return latencyMs != nil && *latencyMs > highLatencyThresholdMs
}

func diagnosis(checks []DiagnosticCheck, issue string, confidence float64, severity, recommendation string) Diagnosis {
	return Diagnosis{
		Issue:          issue,
		Confidence:     confidence,
		Severity:       severity,
		Checks:         checks,
		Recommendation: recommendation,
	}
}
