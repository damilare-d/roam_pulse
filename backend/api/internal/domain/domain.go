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
