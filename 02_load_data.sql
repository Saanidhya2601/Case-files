-- ============================================================
-- Boston Crime Reports Database
-- File: 02_load_data.sql
-- Description: Load data from CSV into normalized tables
-- ============================================================
-- Prerequisites:
--   Dataset: https://www.kaggle.com/datasets/ankkur13/boston-crime-data
--   Place CSV at: /path/to/crime_incidents_report.csv
-- ============================================================

-- Step 1: Create a raw staging table to hold the CSV import as-is
CREATE TEMP TABLE staging_crimes (
    incident_number     TEXT,
    offense_code        TEXT,
    offense_code_group  TEXT,
    offense_description TEXT,
    district            TEXT,
    reporting_area      TEXT,
    shooting            TEXT,
    occurred_on_date    TEXT,
    year                TEXT,
    month               TEXT,
    day_of_week         TEXT,
    hour                TEXT,
    ucr_part            TEXT,
    street              TEXT,
    lat                 TEXT,
    long                TEXT,
    location            TEXT
);

-- Step 2: Bulk-load the raw CSV
COPY staging_crimes
FROM '/path/to/crime_incidents_report.csv'   -- ← update this path
WITH (
    FORMAT CSV,
    HEADER TRUE,
    NULL ''
);

-- Step 3: Populate lookup tables from staging data

-- Offense codes
INSERT INTO crimes.offense_codes (offense_code, offense_description)
SELECT DISTINCT
    TRIM(offense_code)::INTEGER,
    TRIM(offense_description)
FROM staging_crimes
WHERE TRIM(offense_code) ~ '^\d+$'
ON CONFLICT (offense_code) DO NOTHING;

-- Districts
INSERT INTO crimes.districts (district_id, district_name)
VALUES
    ('A1',  'Downtown'),
    ('A15', 'Charlestown'),
    ('A7',  'East Boston'),
    ('B2',  'Roxbury'),
    ('B3',  'Mattapan'),
    ('C6',  'South Boston'),
    ('C11', 'Dorchester'),
    ('D4',  'South End'),
    ('D14', 'Brighton'),
    ('E5',  'West Roxbury'),
    ('E13', 'Jamaica Plain'),
    ('E18', 'Hyde Park')
ON CONFLICT (district_id) DO NOTHING;

-- Streets (normalized)
INSERT INTO crimes.streets (street_name)
SELECT DISTINCT TRIM(street)
FROM staging_crimes
WHERE street IS NOT NULL AND TRIM(street) <> ''
ON CONFLICT (street_name) DO NOTHING;

-- Step 4: Insert into the main fact table (with type casting & validation)
INSERT INTO crimes.reports (
    incident_number,
    offense_code,
    offense_code_group,
    district_id,
    reporting_area,
    shooting,
    occurred_on_date,
    year,
    month,
    day_of_week,
    hour,
    street_id,
    lat,
    long
)
SELECT
    s.incident_number,
    TRIM(s.offense_code)::INTEGER,
    s.offense_code_group,
    CASE WHEN TRIM(s.district) IN (SELECT district_id FROM crimes.districts)
         THEN TRIM(s.district) ELSE NULL END,
    NULLIF(TRIM(s.reporting_area), '')::INTEGER,
    CASE
        WHEN UPPER(TRIM(s.shooting)) = 'Y' THEN 'Y'::crimes.shooting_flag
        ELSE 'N'::crimes.shooting_flag
    END,
    s.occurred_on_date::TIMESTAMP,
    TRIM(s.year)::SMALLINT,
    TRIM(s.month)::SMALLINT,
    TRIM(s.day_of_week)::crimes.day_of_week,
    TRIM(s.hour)::SMALLINT,
    st.street_id,
    NULLIF(TRIM(s.lat), '')::NUMERIC,
    NULLIF(TRIM(s.long), '')::NUMERIC
FROM staging_crimes s
LEFT JOIN crimes.streets st ON st.street_name = TRIM(s.street)
WHERE
    s.incident_number IS NOT NULL
    AND TRIM(s.offense_code) ~ '^\d+$'
    AND TRIM(s.year)  ~ '^\d{4}$'
    AND TRIM(s.month) ~ '^\d{1,2}$'
    AND TRIM(s.hour)  ~ '^\d{1,2}$'
ON CONFLICT (incident_number) DO NOTHING;

-- Step 5: Verify row counts after load
SELECT
    'offense_codes' AS table_name, COUNT(*) AS rows FROM crimes.offense_codes
UNION ALL
SELECT 'districts',  COUNT(*) FROM crimes.districts
UNION ALL
SELECT 'streets',    COUNT(*) FROM crimes.streets
UNION ALL
SELECT 'reports',    COUNT(*) FROM crimes.reports;

-- Step 6: Drop staging table
DROP TABLE staging_crimes;
