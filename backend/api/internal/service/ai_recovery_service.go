package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"roampulse/backend/internal/domain"
	"roampulse/backend/internal/repository"
)

// AIRecoveryService is the Connectivity Recovery Agent: it reuses
// DiagnosticService's gathering logic, asks Claude to turn the
// deterministic diagnosis into a traveler-friendly recommendation, and
// falls back to the deterministic recommendation itself whenever Claude
// is unreachable, unconfigured, or returns something that fails
// validation — see ADR-008. Claude is never called from the mobile app
// directly; this service is the only thing that holds an AIClient.
type AIRecoveryService struct {
	diagnostics *DiagnosticService
	ai          AIClient
	repo        repository.DiagnosticRepository
}

func NewAIRecoveryService(diagnostics *DiagnosticService, ai AIClient, repo repository.DiagnosticRepository) *AIRecoveryService {
	return &AIRecoveryService{diagnostics: diagnostics, ai: ai, repo: repo}
}

// GetRecommendation always returns a recommendation — check
// AIRecommendation.Source to know whether it's genuinely from Claude
// ("ai") or the deterministic engine's own answer wrapped to the same
// shape ("fallback"). It only errors if the deterministic diagnosis
// itself couldn't be produced (the same failure RunDiagnostics would
// hit) — a Claude failure past that point is absorbed, never propagated.
func (s *AIRecoveryService) GetRecommendation(ctx context.Context) (*AIRecommendation, error) {
	diagnosis, planID, err := s.diagnostics.Diagnose(ctx)
	if err != nil {
		return nil, err
	}

	session, err := s.repo.CreateSession(ctx, planID, domain.DiagnosticTriggerUserInitiated)
	if err != nil {
		log.Printf("ai recovery: failed to create diagnostic session: %v", err)
	} else if err := s.saveResult(ctx, session.ID, domain.DiagnosticEngineDeterministic, diagnosis.Issue, diagnosis.Confidence, diagnosis.Severity, diagnosis.Recommendation, diagnosis); err != nil {
		log.Printf("ai recovery: failed to persist deterministic result: %v", err)
	}

	system, user := buildRecoveryPrompt(diagnosis)
	payload, err := s.ai.Recommend(ctx, system, user)
	if err != nil {
		log.Printf("ai recovery: falling back to deterministic recommendation: %v", err)
		rec := fallbackRecommendation(diagnosis)
		return &rec, nil
	}
	if err := validateRecommendationPayload(payload); err != nil {
		log.Printf("ai recovery: rejected malformed AI response, falling back: %v", err)
		rec := fallbackRecommendation(diagnosis)
		return &rec, nil
	}

	rec := AIRecommendation{
		Summary:    payload.Summary,
		Steps:      payload.Steps,
		Confidence: payload.Confidence,
		Escalate:   payload.Escalate,
		Source:     "ai",
	}

	if session != nil {
		if err := s.saveResult(ctx, session.ID, domain.DiagnosticEngineAI, diagnosis.Issue, rec.Confidence, diagnosis.Severity, rec.Summary, rec); err != nil {
			log.Printf("ai recovery: failed to persist AI result: %v", err)
		}
	}

	return &rec, nil
}

func (s *AIRecoveryService) saveResult(ctx context.Context, sessionID string, engine domain.DiagnosticEngineKind, issue string, confidence float64, severity, recommendation string, raw any) error {
	payload, err := json.Marshal(raw)
	if err != nil {
		return fmt.Errorf("marshal result: %w", err)
	}
	return s.repo.SaveResult(ctx, sessionID, domain.DiagnosticResultRecord{
		Engine:         engine,
		Issue:          issue,
		Confidence:     confidence,
		Severity:       severity,
		Recommendation: recommendation,
		RawPayload:     payload,
	})
}
