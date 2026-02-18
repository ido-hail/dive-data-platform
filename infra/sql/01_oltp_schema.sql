-- OLTP schema (App DB)
-- Best practices included:
-- - BIGSERIAL PKs
-- - FK relationships
-- - created_at + updated_at everywhere
-- - checks for data quality
-- - indexes for incremental + joins
-- - auto-updated updated_at trigger

CREATE TABLE IF NOT EXISTS users (
  id            BIGSERIAL PRIMARY KEY,
  full_name     TEXT NOT NULL,
  email         TEXT UNIQUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dive_sites (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  country       TEXT,
  region        TEXT,
  latitude      DOUBLE PRECISION,
  longitude     DOUBLE PRECISION,
  difficulty    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dive_clubs (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  country       TEXT,
  city          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS instructors (
  id            BIGSERIAL PRIMARY KEY,
  full_name     TEXT NOT NULL,
  cert_body     TEXT,
  instructor_no TEXT,
  club_id       BIGINT REFERENCES dive_clubs(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS certifications (
  id            BIGSERIAL PRIMARY KEY,
  cert_body     TEXT NOT NULL,
  cert_name     TEXT NOT NULL,
  level_rank    INT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (cert_body, cert_name)
);

CREATE TABLE IF NOT EXISTS user_certifications (
  user_id          BIGINT NOT NULL REFERENCES users(id),
  certification_id BIGINT NOT NULL REFERENCES certifications(id),
  issued_date      DATE,
  instructor_id    BIGINT REFERENCES instructors(id),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, certification_id)
);

CREATE TABLE IF NOT EXISTS equipment (
  id            BIGSERIAL PRIMARY KEY,
  category      TEXT NOT NULL,
  brand         TEXT,
  model         TEXT,
  serial_no     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dives (
  id            BIGSERIAL PRIMARY KEY,
  user_id       BIGINT NOT NULL REFERENCES users(id),
  site_id       BIGINT REFERENCES dive_sites(id),
  club_id       BIGINT REFERENCES dive_clubs(id),
  instructor_id BIGINT REFERENCES instructors(id),

  start_time    TIMESTAMPTZ NOT NULL,
  end_time      TIMESTAMPTZ NOT NULL,

  max_depth_m   NUMERIC(5,2) NOT NULL CHECK (max_depth_m >= 0),
  avg_depth_m   NUMERIC(5,2) CHECK (avg_depth_m >= 0),
  water_temp_c  NUMERIC(4,1),
  notes         TEXT,

  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

  CHECK (end_time > start_time)
);

CREATE TABLE IF NOT EXISTS dive_equipment (
  dive_id       BIGINT NOT NULL REFERENCES dives(id) ON DELETE CASCADE,
  equipment_id  BIGINT NOT NULL REFERENCES equipment(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (dive_id, equipment_id)
);

CREATE TABLE IF NOT EXISTS dive_conditions (
  id            BIGSERIAL PRIMARY KEY,
  dive_id       BIGINT NOT NULL REFERENCES dives(id) ON DELETE CASCADE,
  visibility_m  NUMERIC(4,1) CHECK (visibility_m >= 0),
  current_level TEXT,
  swell_level   TEXT,
  weather       TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- indexes for incremental + joins
CREATE INDEX IF NOT EXISTS idx_users_updated_at  ON users(updated_at);
CREATE INDEX IF NOT EXISTS idx_sites_updated_at  ON dive_sites(updated_at);
CREATE INDEX IF NOT EXISTS idx_dives_updated_at  ON dives(updated_at);
CREATE INDEX IF NOT EXISTS idx_dives_user_id     ON dives(user_id);
CREATE INDEX IF NOT EXISTS idx_dives_site_id     ON dives(site_id);

-- auto-update updated_at on UPDATE
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_users_set_updated_at') THEN
    CREATE TRIGGER trg_users_set_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_dive_sites_set_updated_at') THEN
    CREATE TRIGGER trg_dive_sites_set_updated_at
    BEFORE UPDATE ON dive_sites
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_dive_clubs_set_updated_at') THEN
    CREATE TRIGGER trg_dive_clubs_set_updated_at
    BEFORE UPDATE ON dive_clubs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_instructors_set_updated_at') THEN
    CREATE TRIGGER trg_instructors_set_updated_at
    BEFORE UPDATE ON instructors
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_certifications_set_updated_at') THEN
    CREATE TRIGGER trg_certifications_set_updated_at
    BEFORE UPDATE ON certifications
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_user_certifications_set_updated_at') THEN
    CREATE TRIGGER trg_user_certifications_set_updated_at
    BEFORE UPDATE ON user_certifications
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_equipment_set_updated_at') THEN
    CREATE TRIGGER trg_equipment_set_updated_at
    BEFORE UPDATE ON equipment
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_dives_set_updated_at') THEN
    CREATE TRIGGER trg_dives_set_updated_at
    BEFORE UPDATE ON dives
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_dive_conditions_set_updated_at') THEN
    CREATE TRIGGER trg_dive_conditions_set_updated_at
    BEFORE UPDATE ON dive_conditions
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
  END IF;
END $$;
