-- Generic staging layer for legacy extraction.
-- This avoids forcing the normalized database to carry 1,180 legacy tables.

CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.legacy_raw_record (
    id bigserial PRIMARY KEY,
    legacy_source_code text NOT NULL,
    legacy_table text NOT NULL,
    legacy_pk jsonb NOT NULL,
    record_data jsonb NOT NULL,
    record_hash text,
    extracted_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_legacy_raw_record_source_pk
ON staging.legacy_raw_record (legacy_source_code, legacy_table, (legacy_pk::text));

CREATE INDEX IF NOT EXISTS idx_legacy_raw_source_table
ON staging.legacy_raw_record (legacy_source_code, legacy_table);

CREATE INDEX IF NOT EXISTS idx_legacy_raw_record_data_gin
ON staging.legacy_raw_record USING gin (record_data jsonb_path_ops);

CREATE TABLE IF NOT EXISTS staging.migration_batch (
    id bigserial PRIMARY KEY,
    batch_code text NOT NULL UNIQUE,
    description text,
    started_at timestamptz NOT NULL DEFAULT now(),
    finished_at timestamptz,
    status text NOT NULL DEFAULT 'running',
    metrics jsonb NOT NULL DEFAULT '{}'::jsonb
);
