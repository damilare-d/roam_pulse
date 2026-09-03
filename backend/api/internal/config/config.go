// Package config loads RoamPulse backend configuration from the
// environment. There is no config file format — every setting is an env
// var, following .env.example at the repo root of backend/api.
package config

import (
	"fmt"
	"os"
)

type Config struct {
	Port        string
	DatabaseURL string
}

// Load reads configuration from the environment, returning an error for
// anything required that's missing rather than silently defaulting —
// a missing DATABASE_URL should fail fast, not connect to nothing.
func Load() (Config, error) {
	cfg := Config{
		Port:        getEnv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
	}

	if cfg.DatabaseURL == "" {
		return Config{}, fmt.Errorf("config: DATABASE_URL is required")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
