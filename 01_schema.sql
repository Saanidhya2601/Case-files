-- ============================================================
-- Boston Crime Reports Database
-- File: 01_schema.sql
-- Description: Database and schema creation
-- Author: Portfolio Project
-- ============================================================

-- Step 1: Create the database (run as superuser in psql)
-- CREATE DATABASE boston_crimes;

-- Step 2: Connect to the database
-- \c boston_crimes

-- Step 3: Create a dedicated schema
CREATE SCHEMA IF NOT EXISTS crimes;

-- ============================================================
-- Enumerated Types (custom data types for constrained columns)
-- ============================================================

-- Day of week type
CREATE TYPE crimes.day_of_week AS ENUM (
    'Sunday', 'Monday', 'Tuesday', 'Wednesday',
    'Thursday', 'Friday', 'Saturday'
);

-- Shooting flag type
CREATE TYPE crimes.shooting_flag AS ENUM ('Y', 'N');

-- ============================================================
-- Core Tables
-- ============================================================

-- Offense codes lookup table (normalized)
CREATE TABLE crimes.offense_codes (
    offense_code        INTEGER         PRIMARY KEY,
    offense_description VARCHAR(255)    NOT NULL
);

-- Districts lookup table (normalized)
CREATE TABLE crimes.districts (
    district_id     CHAR(3)         PRIMARY KEY,
    district_name   VARCHAR(100)    NOT NULL
);

-- Streets lookup table (normalized)
CREATE TABLE crimes.streets (
    street_id   SERIAL          PRIMARY KEY,
    street_name VARCHAR(255)    NOT NULL UNIQUE
);

-- ============================================================
-- Main Crime Reports Fact Table
-- ============================================================

CREATE TABLE crimes.reports (
    incident_number     VARCHAR(20)             PRIMARY KEY,
    offense_code        INTEGER                 NOT NULL REFERENCES crimes.offense_codes(offense_code),
    offense_code_group  VARCHAR(100),
    district_id         CHAR(3)                 REFERENCES crimes.districts(district_id),
    reporting_area      INTEGER,
    shooting            crimes.shooting_flag    DEFAULT 'N',
    occurred_on_date    TIMESTAMP               NOT NULL,
    year                SMALLINT                NOT NULL CHECK (year BETWEEN 2000 AND 2100),
    month               SMALLINT                NOT NULL CHECK (month BETWEEN 1 AND 12),
    day_of_week         crimes.day_of_week      NOT NULL,
    hour                SMALLINT                NOT NULL CHECK (hour BETWEEN 0 AND 23),
    street_id           INTEGER                 REFERENCES crimes.streets(street_id),
    lat                 NUMERIC(9, 6),
    long                NUMERIC(9, 6)
);

-- ============================================================
-- Indexes for Query Performance
-- ============================================================

CREATE INDEX idx_reports_offense_code    ON crimes.reports (offense_code);
CREATE INDEX idx_reports_district        ON crimes.reports (district_id);
CREATE INDEX idx_reports_occurred_on     ON crimes.reports (occurred_on_date);
CREATE INDEX idx_reports_year_month      ON crimes.reports (year, month);
CREATE INDEX idx_reports_shooting        ON crimes.reports (shooting);
CREATE INDEX idx_reports_day_hour        ON crimes.reports (day_of_week, hour);

-- ============================================================
-- Comments / Documentation
-- ============================================================

COMMENT ON SCHEMA crimes IS 'Schema for Boston Police Department crime incident reports';
COMMENT ON TABLE crimes.reports IS 'Fact table storing individual crime incident records';
COMMENT ON TABLE crimes.offense_codes IS 'Lookup table mapping offense codes to descriptions';
COMMENT ON TABLE crimes.districts IS 'Lookup table for Boston PD district identifiers';
COMMENT ON TABLE crimes.streets IS 'Normalized street name lookup to reduce data redundancy';

COMMENT ON COLUMN crimes.reports.incident_number  IS 'Unique identifier for each crime incident';
COMMENT ON COLUMN crimes.reports.offense_code     IS 'Numeric code identifying the type of offense';
COMMENT ON COLUMN crimes.reports.shooting         IS 'Flag indicating whether a shooting was involved (Y/N)';
COMMENT ON COLUMN crimes.reports.reporting_area   IS 'Boston PD reporting area number';
COMMENT ON COLUMN crimes.reports.lat              IS 'Latitude coordinate of the incident location';
COMMENT ON COLUMN crimes.reports.long             IS 'Longitude coordinate of the incident location';
