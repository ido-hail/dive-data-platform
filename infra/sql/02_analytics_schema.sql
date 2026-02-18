-- Analytics schema (Warehouse DB)

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS stg;
CREATE SCHEMA IF NOT EXISTS mart;
CREATE SCHEMA IF NOT EXISTS ops;

-- Watermarks for batch incremental extraction
CREATE TABLE IF NOT EXISTS ops.watermarks (
  source_name       TEXT PRIMARY KEY,   -- 'users', 'dives', ...
  last_updated_at   TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- DLQ for invalid events (Kafka Phase 2)
CREATE TABLE IF NOT EXISTS ops.event_errors (
  error_id        BIGSERIAL PRIMARY KEY,
  event_id        TEXT,
  event_type      TEXT,
  error_code      TEXT NOT NULL,
  error_message   TEXT NOT NULL,
  raw_event       JSONB,
  pipeline_run_id TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_errors_created_at ON ops.event_errors(created_at);
CREATE INDEX IF NOT EXISTS idx_event_errors_event_type ON ops.event_errors(event_type);
