// Package service is the application layer: it composes repository calls
// into the shapes the HTTP layer needs, and is where cross-repository
// aggregation logic (e.g. data remaining = allowance - usage) lives. See
// docs/ARCHITECTURE.md's layering diagram.
package service

import (
	"time"

	"roampulse/backend/internal/domain"
)

type TripSummary struct {
	Traveller   domain.TravellerProfile `json:"traveller"`
	Destination domain.Destination      `json:"destination"`
	Network     domain.Network          `json:"network"`
	Plan        domain.TravelPlan       `json:"plan"`
}

type PlanSummary struct {
	Plan            domain.TravelPlan `json:"plan"`
	DataAllowanceMB float64           `json:"dataAllowanceMb"`
	DataUsedMB      float64           `json:"dataUsedMb"`
	DataRemainingMB float64           `json:"dataRemainingMb"`
	DaysRemaining   int               `json:"daysRemaining"`
}

type UsageSummary struct {
	PlanID         string           `json:"planId"`
	TotalBytesUsed int64            `json:"totalBytesUsed"`
	ByCategory     map[string]int64 `json:"byCategory"`
}

type ConnectivityStatus struct {
	State          domain.ConnectivityState `json:"state"`
	Network        domain.Network           `json:"network"`
	SignalStrength string                   `json:"signalStrength"`
	LatencyMs      *int                     `json:"latencyMs,omitempty"`
	DownloadMbps   *float64                 `json:"downloadMbps,omitempty"`
	UploadMbps     *float64                 `json:"uploadMbps,omitempty"`
	LastEventAt    time.Time                `json:"lastEventAt"`
}
