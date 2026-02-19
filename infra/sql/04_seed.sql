-- ==========================================================
-- Dive Data Platform - OLTP Seed (minimal, deterministic)
-- Run manually via psql (NOT entrypoint init)
-- ==========================================================

-- Optional reset (ONLY if you want a clean slate):
-- TRUNCATE TABLE dives, dive_sites, users RESTART IDENTITY CASCADE;

-- -------------
-- Users (10)
-- -------------
INSERT INTO users (full_name, email)
SELECT
  'Seed User ' || gs AS full_name,
  'seed.user+' || gs || '@example.com' AS email
FROM generate_series(1, 10) gs
ON CONFLICT (email) DO NOTHING;

-- -----------------
-- Dive Sites (20)
-- -----------------
-- We avoid assuming a UNIQUE constraint exists on name,
-- so we insert only if the name doesn't already exist.
WITH new_sites AS (
  SELECT
    'Seed Site ' || gs AS name,
    CASE
      WHEN gs % 4 = 0 THEN 'Israel'
      WHEN gs % 4 = 1 THEN 'Greece'
      WHEN gs % 4 = 2 THEN 'Egypt'
      ELSE 'Cyprus'
    END AS country,
    'Region ' || ((gs - 1) % 5 + 1) AS region,
    (32.0 + (gs * 0.05))::double precision AS latitude,
    (34.7 + (gs * 0.05))::double precision AS longitude,
    CASE
      WHEN gs % 3 = 0 THEN 'Beginner'
      WHEN gs % 3 = 1 THEN 'Intermediate'
      ELSE 'Advanced'
    END AS difficulty
  FROM generate_series(1, 20) gs
)
INSERT INTO dive_sites (name, country, region, latitude, longitude, difficulty)
SELECT s.name, s.country, s.region, s.latitude, s.longitude, s.difficulty
FROM new_sites s
WHERE NOT EXISTS (
  SELECT 1 FROM dive_sites ds WHERE ds.name = s.name
);

-- -----------------
-- Dives (100)
-- -----------------
-- Create 100 dives for seeded users.
-- site_id is sometimes NULL to test optional FK.
-- Times and notes are deterministic-ish.
WITH u AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM users
  WHERE email LIKE 'seed.user+%@example.com'
),
s AS (
  SELECT id, row_number() OVER (ORDER BY id) AS rn
  FROM dive_sites
  WHERE name LIKE 'Seed Site %'
),
gen AS (
  SELECT gs AS n
  FROM generate_series(1, 100) gs
),
rows_to_insert AS (
  SELECT
    (SELECT id FROM u WHERE rn = ((n - 1) % 10) + 1) AS user_id,
    CASE
      WHEN n % 5 = 0 THEN NULL
      ELSE (SELECT id FROM s WHERE rn = ((n - 1) % 20) + 1)
    END AS site_id,
    NULL::bigint AS club_id,
    NULL::bigint AS instructor_id,
    -- start/end times within last ~7 days, spaced by minutes
    (now() - (interval '7 days') + (n * interval '20 minutes')) AS start_time,
    (now() - (interval '7 days') + (n * interval '20 minutes') + interval '45 minutes') AS end_time,
    -- optional depth/temp sometimes NULL to exercise nullable fields
    CASE WHEN n % 6 = 0 THEN NULL ELSE (10 + (n % 25))::double precision END AS max_depth_m,
    CASE WHEN n % 7 = 0 THEN NULL ELSE (6 + (n % 18))::double precision END AS avg_depth_m,
    CASE WHEN n % 8 = 0 THEN NULL ELSE (18 + (n % 8))::double precision END AS water_temp_c,
    ('Seed dive #' || n) AS notes
  FROM gen
)
INSERT INTO dives (
  user_id, site_id, club_id, instructor_id,
  start_time, end_time,
  max_depth_m, avg_depth_m, water_temp_c, notes
)
SELECT
  user_id, site_id, club_id, instructor_id,
  start_time, end_time,
  max_depth_m, avg_depth_m, water_temp_c, notes
FROM rows_to_insert;
