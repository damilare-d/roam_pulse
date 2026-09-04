// Package domain holds RoamPulse's core models — plain structs with no
// persistence or transport concerns. Repository interfaces live in
// internal/repository and are implemented against these types.
package domain

import "time"

type TravellerProfile struct {
	ID          string    `json:"id"`
	DisplayName string    `json:"displayName"`
	HomeCountry string    `json:"homeCountry"`
	CreatedAt   time.Time `json:"createdAt"`
}

type Destination struct {
	ID          string `json:"id"`
	CountryCode string `json:"countryCode"`
	City        string `json:"city"`
	Timezone    string `json:"timezone"`
}

type Network struct {
	ID            string `json:"id"`
	DestinationID string `json:"destinationId"`
	CarrierName   string `json:"carrierName"`
	Technology    string `json:"technology"`
	MCC           string `json:"mcc"`
	MNC           string `json:"mnc"`
}

// EsimStatus mirrors the esims.status CHECK constraint.
type EsimStatus string

const (
	EsimStatusInactive  EsimStatus = "inactive"
	EsimStatusActive    EsimStatus = "active"
	EsimStatusSuspended EsimStatus = "suspended"
	EsimStatusExpired   EsimStatus = "expired"
)

type Esim struct {
	ID             string     `json:"id"`
	TravellerID    string     `json:"travellerId"`
	IccidSimulated string     `json:"iccidSimulated"`
	Status         EsimStatus `json:"status"`
	ActivatedAt    *time.Time `json:"activatedAt,omitempty"`
}

// PlanStatus mirrors the travel_plans.status CHECK constraint.
type PlanStatus string

const (
	PlanStatusUpcoming  PlanStatus = "upcoming"
	PlanStatusActive    PlanStatus = "active"
	PlanStatusCompleted PlanStatus = "completed"
	PlanStatusExpired   PlanStatus = "expired"
)

type TravelPlan struct {
	ID              string     `json:"id"`
	TravellerID     string     `json:"travellerId"`
	DestinationID   string     `json:"destinationId"`
	EsimID          string     `json:"esimId"`
	StartsAt        time.Time  `json:"startsAt"`
	ExpiresAt       time.Time  `json:"expiresAt"`
	DataAllowanceMB int        `json:"dataAllowanceMb"`
	Status          PlanStatus `json:"status"`
}

// ConnectivityState mirrors the state machine in docs/ARCHITECTURE.md
// section 4 — never represent connectivity with an arbitrary boolean.
type ConnectivityState string

const (
	ConnectivityUnknown       ConnectivityState = "unknown"
	ConnectivityConnecting    ConnectivityState = "connecting"
	ConnectivityConnected     ConnectivityState = "connected"
	ConnectivityDegraded      ConnectivityState = "degraded"
	ConnectivityOffline       ConnectivityState = "offline"
	ConnectivitySynchronizing ConnectivityState = "synchronizing"
	ConnectivityError         ConnectivityState = "error"
)

type NetworkSession struct {
	ID             string     `json:"id"`
	PlanID         string     `json:"planId"`
	NetworkID      string     `json:"networkId"`
	ConnectedAt    time.Time  `json:"connectedAt"`
	DisconnectedAt *time.Time `json:"disconnectedAt,omitempty"`
	SignalStrength string     `json:"signalStrength"`
	LatencyMs      *int       `json:"latencyMs,omitempty"`
	DownloadMbps   *float64   `json:"downloadMbps,omitempty"`
	UploadMbps     *float64   `json:"uploadMbps,omitempty"`
}

type UsageRecord struct {
	ID         string    `json:"id"`
	PlanID     string    `json:"planId"`
	RecordedAt time.Time `json:"recordedAt"`
	Category   string    `json:"category"`
	BytesUsed  int64     `json:"bytesUsed"`
}

type ConnectivityEvent struct {
	ID         string            `json:"id"`
	PlanID     string            `json:"planId"`
	OccurredAt time.Time         `json:"occurredAt"`
	FromState  ConnectivityState `json:"fromState"`
	ToState    ConnectivityState `json:"toState"`
	Reason     string            `json:"reason,omitempty"`
}

// DiagnosticTrigger mirrors the diagnostic_sessions.trigger CHECK
// constraint. Only UserInitiated is used until Phase 9's Chaos Mode and
// automatic degraded/offline detection wire up the other two.
type DiagnosticTrigger string

const (
	DiagnosticTriggerUserInitiated DiagnosticTrigger = "user_initiated"
	DiagnosticTriggerAutoDegraded  DiagnosticTrigger = "auto_degraded"
	DiagnosticTriggerAutoOffline   DiagnosticTrigger = "auto_offline"
)

type DiagnosticSession struct {
	ID          string
	PlanID      string
	StartedAt   time.Time
	CompletedAt *time.Time
	Trigger     DiagnosticTrigger
}

// DiagnosticEngine mirrors the diagnostic_results.engine CHECK constraint
// — "deterministic" today, "ai" once Phase 11 adds the Claude-backed
// engine writing to the same table.
type DiagnosticEngineKind string

const (
	DiagnosticEngineDeterministic DiagnosticEngineKind = "deterministic"
	DiagnosticEngineAI            DiagnosticEngineKind = "ai"
)

type DiagnosticResultRecord struct {
	ID             string
	SessionID      string
	Engine         DiagnosticEngineKind
	Issue          string
	Confidence     float64
	Severity       string
	Recommendation string
	RawPayload     []byte // the full Diagnosis, JSON-encoded — see diagnostic_results.raw_payload
	CreatedAt      time.Time
}
