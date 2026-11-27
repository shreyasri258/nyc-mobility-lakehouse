--- one-time setup for NYC Mobility Lakehouse

CREATE CATALOG IF NOT EXISTS mobility
  COMMENT 'NYC Mobility Lakehouse: TLC trips, congestion pricing analysis';

USE CATALOG mobility;

CREATE SCHEMA IF NOT EXISTS landing COMMENT 'Raw uploaded files (volumes only)';
CREATE SCHEMA IF NOT EXISTS bronze  COMMENT 'Raw Delta tables from Auto Loader / COPY INTO';
CREATE SCHEMA IF NOT EXISTS silver  COMMENT 'Cleaned, deduplicated trips + quarantine';
CREATE SCHEMA IF NOT EXISTS gold    COMMENT 'Star schema and aggregates for BI';
CREATE SCHEMA IF NOT EXISTS ops     COMMENT 'Ingestion log, DQ results, metrics, checkpoints';

CREATE VOLUME IF NOT EXISTS mobility.landing.raw
  COMMENT 'Manually uploaded TLC Parquet and reference CSVs';
CREATE VOLUME IF NOT EXISTS mobility.ops.checkpoints
  COMMENT 'Auto Loader schema locations and streaming checkpoints';

-- Verify
SHOW SCHEMAS IN mobility;
SHOW VOLUMES IN mobility.landing;
SHOW VOLUMES IN mobility.ops;


LIST '/Volumes/mobility/landing/raw/yellow/';
LIST '/Volumes/mobility/landing/raw/green/';
LIST '/Volumes/mobility/landing/raw/reference/';