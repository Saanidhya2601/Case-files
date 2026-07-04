-- ============================================================
-- Boston Crime Reports Database
-- File: 05_views.sql
-- Description: Reusable views for common reporting queries
-- ============================================================

-- ============================================================
-- View 1: Full enriched crime report (denormalized for easy access)
-- ============================================================

CREATE OR REPLACE VIEW crimes.v_crime_summary AS
SELECT
    r.incident_number,
    oc.offense_code,
    oc.offense_description,
    r.offense_code_group,
    d.district_id,
    d.district_name,
    r.reporting_area,
    r.shooting,
    r.occurred_on_date,
    r.year,
    r.month,
    r.day_of_week,
    r.hour,
    st.street_name,
    r.lat,
    r.long
FROM crimes.reports r
JOIN crimes.offense_codes oc ON r.offense_code = oc.offense_code
LEFT JOIN crimes.districts d  ON r.district_id  = d.district_id
LEFT JOIN crimes.streets   st ON r.street_id    = st.street_id;

COMMENT ON VIEW crimes.v_crime_summary IS
    'Denormalized view joining all dimension tables for easy querying';

-- ============================================================
-- View 2: Yearly district crime stats
-- ============================================================

CREATE OR REPLACE VIEW crimes.v_district_yearly AS
SELECT
    r.year,
    d.district_id,
    d.district_name,
    COUNT(*)                                       AS total_incidents,
    COUNT(*) FILTER (WHERE r.shooting = 'Y')       AS shooting_incidents,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE r.shooting = 'Y') / COUNT(*), 2
    )                                              AS shooting_rate_pct
FROM crimes.reports r
JOIN crimes.districts d ON r.district_id = d.district_id
GROUP BY r.year, d.district_id, d.district_name;

COMMENT ON VIEW crimes.v_district_yearly IS
    'Annual crime totals and shooting rates rolled up by district';

-- ============================================================
-- View 3: Hourly heatmap data (for dashboards)
-- ============================================================

CREATE OR REPLACE VIEW crimes.v_hourly_heatmap AS
SELECT
    day_of_week,
    hour,
    COUNT(*) AS incident_count
FROM crimes.reports
GROUP BY day_of_week, hour
ORDER BY
    CASE day_of_week
        WHEN 'Monday'    THEN 1
        WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5
        WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END,
    hour;

COMMENT ON VIEW crimes.v_hourly_heatmap IS
    'Day-of-week × hour incident counts for heatmap visualizations';

-- ============================================================
-- View 4: Top offense groups per year
-- ============================================================

CREATE OR REPLACE VIEW crimes.v_top_offenses_by_year AS
WITH ranked AS (
    SELECT
        year,
        offense_code_group,
        COUNT(*) AS incident_count,
        RANK() OVER (PARTITION BY year ORDER BY COUNT(*) DESC) AS rnk
    FROM crimes.reports
    WHERE offense_code_group IS NOT NULL
    GROUP BY year, offense_code_group
)
SELECT year, offense_code_group, incident_count, rnk
FROM ranked
WHERE rnk <= 5;

COMMENT ON VIEW crimes.v_top_offenses_by_year IS
    'Top 5 offense categories per year based on incident volume';

-- ============================================================
-- View 5: Shooting hotspots
-- ============================================================

CREATE OR REPLACE VIEW crimes.v_shooting_hotspots AS
SELECT
    st.street_name,
    d.district_name,
    COUNT(*) AS shooting_count,
    ROUND(AVG(r.lat)::NUMERIC, 6)  AS avg_lat,
    ROUND(AVG(r.long)::NUMERIC, 6) AS avg_long
FROM crimes.reports r
JOIN crimes.streets   st ON r.street_id    = st.street_id
JOIN crimes.districts d  ON r.district_id  = d.district_id
WHERE r.shooting = 'Y'
GROUP BY st.street_name, d.district_name
HAVING COUNT(*) >= 3
ORDER BY shooting_count DESC;

COMMENT ON VIEW crimes.v_shooting_hotspots IS
    'Streets with 3+ shooting incidents, with average coordinates for mapping';
