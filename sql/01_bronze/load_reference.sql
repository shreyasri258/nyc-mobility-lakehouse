-- load_reference.sql: Phase 1, bronze reference tables loaded with COPY INTO
--
-- COPY INTO is idempotent: it records which files it has already loaded, so
-- running this script again loads 0 new rows. Run it on the SQL warehouse
-- (SQL editor) or in a notebook on serverless compute.

USE CATALOG mobility;

-- 1. TLC taxi zone lookup ----------------------------------------------------

CREATE TABLE IF NOT EXISTS bronze.taxi_zone_raw (
  LocationID    INT       COMMENT 'TLC taxi zone ID used in PULocationID / DOLocationID',
  Borough       STRING,
  Zone          STRING,
  service_zone  STRING    COMMENT 'Yellow Zone, Boro Zone, Airports, EWR, N/A',
  _source_file  STRING,
  _ingested_at  TIMESTAMP
)
COMMENT 'TLC taxi zone lookup (raw), loaded with COPY INTO';

COPY INTO bronze.taxi_zone_raw
FROM (
  SELECT
    CAST(LocationID AS INT) AS LocationID,
    Borough,
    Zone,
    service_zone,
    _metadata.file_path     AS _source_file,
    current_timestamp()     AS _ingested_at
  FROM '/Volumes/mobility/landing/raw/reference/'
)
FILEFORMAT = CSV
FILES = ('taxi_zone_lookup.csv')
FORMAT_OPTIONS ('header' = 'true');

-- 2. MTA Congestion Relief Zone taxi zones -----------------------------------
-- The polygon column holds long multi-line text, hence multiLine + escape.
-- Column names are made Delta-friendly (no spaces).

CREATE TABLE IF NOT EXISTS bronze.cbd_zones_raw (
  taxi_zone     INT       COMMENT 'TLC LocationID inside the MTA Congestion Relief Zone',
  polygon       STRING    COMMENT 'Zone boundary as published by MTA (not used downstream)',
  _source_file  STRING,
  _ingested_at  TIMESTAMP
)
COMMENT 'MTA CBD taxi zones (raw), loaded with COPY INTO';

COPY INTO bronze.cbd_zones_raw
FROM (
  SELECT
    CAST(`Taxi Zone` AS INT) AS taxi_zone,
    Polygon                  AS polygon,
    _metadata.file_path      AS _source_file,
    current_timestamp()      AS _ingested_at
  FROM '/Volumes/mobility/landing/raw/reference/'
)
FILEFORMAT = CSV
FILES = ('mta_cbd_taxi_zones.csv')
FORMAT_OPTIONS ('header' = 'true', 'multiLine' = 'true', 'escape' = '"');

-- 3. Checks ------------------------------------------------------------------

SELECT 'taxi_zone_raw' AS table_name, COUNT(*) AS row_count, 265 AS expected FROM bronze.taxi_zone_raw
UNION ALL
SELECT 'cbd_zones_raw', COUNT(*), 38 FROM bronze.cbd_zones_raw;

-- 4. Idempotency proof -------------------------------------------------------
-- Run the two COPY INTO statements again (just re-run this whole file).
-- Each should report num_inserted_rows = 0, and the counts above stay 265 and 38.
-- Save a screenshot of the 0-row result for the README.

-- Outputs: 256 (taxi zones_raw) and 38 (cbd_zones_raw)