# Dive Data Platform

Hybrid Batch + Streaming Data Engineering Platform (MVP + AWS S3 + Kafka events phase).

## Architecture

Batch lane:
Postgres OLTP → Prefect → AWS S3 (raw zone) → Postgres Analytics (raw → stg → mart) → Metabase

Streaming lane (Phase 2, local):
FastAPI → Kafka → Consumer (Pydantic contracts) → Mongo (valid) / Postgres ops.event_errors (invalid)

## Stack

- FastAPI (API)
- Streamlit (UI)
- Postgres (OLTP + Analytics)
- Prefect (orchestration)
- dbt-core (transforms + tests)
- Metabase (dashboards)
- Kafka (events only, Phase 2)
- AWS S3 (minimal cloud raw zone)

## Status

Phase 0 — Repo & Local Infrastructure Skeleton
