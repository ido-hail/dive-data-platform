-- Migration: optional depth fields

-- Add max depth attribute for dive sites (metadata)
ALTER TABLE dive_sites
ADD COLUMN IF NOT EXISTS max_depth_m DOUBLE PRECISION;

-- Allow saving dives without max depth (optional input)
ALTER TABLE dives
ALTER COLUMN max_depth_m DROP NOT NULL;
