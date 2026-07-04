-- ============================================================
-- Boston Crime Reports Database
-- File: 04_analysis_queries.sql
-- Description: Analytical queries to extract crime insights
-- ============================================================

-- ============================================================
-- Q1. Total crime incidents per year
-- ============================================================

SELECT
    year,
    COUNT(*) AS total_incidents
FROM crimes.reports
GROUP BY year
ORDER BY year;

-- ============================================================
-- Q2. Top 10 most common offense types
-- ============================================================

SELECT
    oc.offense_description,
    COUNT(r.incident_number) AS incident_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM crimes.reports r
JOIN crimes.offense_codes oc ON r.offense_code = oc.offense_code
GROUP BY oc.offense_description
ORDER BY incident_count DESC
LIMIT 10;

-- ============================================================
-- Q3. Crime count by district (with district name)
-- ============================================================

SELECT
    d.district_id,
    d.district_name,
    COUNT(r.incident_number) AS total_incidents,
    RANK() OVER (ORDER BY COUNT(r.incident_number) DESC) AS district_rank
FROM crimes.reports r
JOIN crimes.districts d ON r.district_id = d.district_id
GROUP BY d.district_id, d.district_name
ORDER BY total_incidents DESC;

-- ============================================================
-- Q4. Shooting incidents by district (% breakdown)
-- ============================================================

SELECT
    d.district_name,
    COUNT(*) FILTER (WHERE r.shooting = 'Y') AS shooting_incidents,
    COUNT(*) AS total_incidents,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE r.shooting = 'Y') / COUNT(*),
        2
    ) AS shooting_pct
FROM crimes.reports r
JOIN crimes.districts d ON r.district_id = d.district_id
GROUP BY d.district_name
ORDER BY shooting_pct DESC;

-- ============================================================
-- Q5. Crime by hour of day (identify peak hours)
-- ============================================================

SELECT
    hour,
    COUNT(*) AS incident_count,
    REPEAT('█', (COUNT(*) / 1000)::INT) AS bar_chart   -- visual bar in psql
FROM crimes.reports
GROUP BY hour
ORDER BY hour;

-- ============================================================
-- Q6. Crime by day of week
-- ============================================================

SELECT
    day_of_week,
    COUNT(*) AS incident_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_share
FROM crimes.reports
GROUP BY day_of_week
ORDER BY
    CASE day_of_week
        WHEN 'Monday'    THEN 1
        WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5
        WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END;

-- ============================================================
-- Q7. Monthly crime trend (year-over-year comparison)
-- ============================================================

SELECT
    year,
    month,
    COUNT(*) AS incident_count,
    LAG(COUNT(*)) OVER (PARTITION BY month ORDER BY year) AS prior_year_count,
    COUNT(*) - LAG(COUNT(*)) OVER (PARTITION BY month ORDER BY year) AS yoy_change
FROM crimes.reports
GROUP BY year, month
ORDER BY year, month;

-- ============================================================
-- Q8. Most dangerous streets (top 15)
-- ============================================================

SELECT
    st.street_name,
    COUNT(r.incident_number) AS total_incidents,
    COUNT(*) FILTER (WHERE r.shooting = 'Y') AS shooting_incidents
FROM crimes.reports r
JOIN crimes.streets st ON r.street_id = st.street_id
GROUP BY st.street_name
ORDER BY total_incidents DESC
LIMIT 15;

-- ============================================================
-- Q9. Rolling 3-month average of incidents (window function)
-- ============================================================

WITH monthly_counts AS (
    SELECT
        year,
        month,
        COUNT(*) AS incident_count
    FROM crimes.reports
    GROUP BY year, month
)
SELECT
    year,
    month,
    incident_count,
    ROUND(
        AVG(incident_count) OVER (
            ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ), 1
    ) AS rolling_3mo_avg
FROM monthly_counts
ORDER BY year, month;

-- ============================================================
-- Q10. Offense group distribution using CTEs
-- ============================================================

WITH offense_totals AS (
    SELECT
        offense_code_group,
        COUNT(*) AS incident_count
    FROM crimes.reports
    WHERE offense_code_group IS NOT NULL
    GROUP BY offense_code_group
),
ranked AS (
    SELECT
        offense_code_group,
        incident_count,
        ROUND(100.0 * incident_count / SUM(incident_count) OVER (), 2) AS pct,
        RANK() OVER (ORDER BY incident_count DESC) AS rnk
    FROM offense_totals
)
SELECT *
FROM ranked
ORDER BY rnk;

-- ============================================================
-- Q11. Peak crime hours per district (advanced aggregation)
-- ============================================================

WITH hourly_by_district AS (
    SELECT
        d.district_name,
        r.hour,
        COUNT(*) AS incident_count,
        RANK() OVER (
            PARTITION BY d.district_name
            ORDER BY COUNT(*) DESC
        ) AS hour_rank
    FROM crimes.reports r
    JOIN crimes.districts d ON r.district_id = d.district_id
    GROUP BY d.district_name, r.hour
)
SELECT district_name, hour AS peak_hour, incident_count
FROM hourly_by_district
WHERE hour_rank = 1
ORDER BY incident_count DESC;

-- ============================================================
-- Q12. Incidents with coordinates (for geospatial mapping)
-- ============================================================

SELECT
    r.incident_number,
    oc.offense_description,
    d.district_name,
    r.occurred_on_date,
    r.lat,
    r.long
FROM crimes.reports r
JOIN crimes.offense_codes oc ON r.offense_code = oc.offense_code
JOIN crimes.districts      d  ON r.district_id  = d.district_id
WHERE r.lat IS NOT NULL
  AND r.long IS NOT NULL
  AND r.shooting = 'Y'
ORDER BY r.occurred_on_date DESC
LIMIT 500;
