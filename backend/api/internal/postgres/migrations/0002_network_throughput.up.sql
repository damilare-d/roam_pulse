-- Connection health throughput, alongside the existing latency_ms — the
-- dashboard's "Connection health" section (docs/PRODUCT_DISCOVERY.md
-- section 7) shows latency/download/upload together.
ALTER TABLE network_sessions
    ADD COLUMN download_mbps DOUBLE PRECISION,
    ADD COLUMN upload_mbps DOUBLE PRECISION;
