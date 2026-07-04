# 🔍 Building a Database for Crime Reports
### PostgreSQL Portfolio Project | Intermediate SQL

---

## Project Overview

This project demonstrates database engineering skills by designing, building, and querying a **PostgreSQL database** for Boston Police Department crime incident reports. It covers the full lifecycle: schema design, data normalization, bulk loading, role-based access control, and analytical querying.

**Difficulty:** Intermediate  
**Tech Stack:** PostgreSQL · SQL · Python (optional)  
**Dataset:** [Boston Crime Data – Kaggle](https://www.kaggle.com/datasets/ankkur13/boston-crime-data)

---

## Skills Demonstrated

| Skill | Details |
|---|---|
| Database Design | Normalized schema with fact + dimension tables |
| Custom Data Types | PostgreSQL `ENUM` types for constrained columns |
| Data Loading | Staging table → `COPY` → validated inserts |
| Indexing | Multi-column indexes for query performance |
| Security (RBAC) | User groups, roles, `GRANT`/`REVOKE` |
| Window Functions | `LAG`, `RANK`, `AVG OVER` for trend analysis |
| CTEs | Multi-step queries with `WITH` clauses |
| Views | Reusable denormalized views for reporting |
| Aggregations | `FILTER`, `ROUND`, `PARTITION BY` |

---

## Database Schema

```
crimes schema
│
├── offense_codes    (lookup)  offense_code PK, offense_description
├── districts        (lookup)  district_id PK, district_name
├── streets          (lookup)  street_id PK, street_name
│
└── reports          (fact)    incident_number PK
                               ├── offense_code  → FK offense_codes
                               ├── district_id   → FK districts
                               ├── street_id     → FK streets
                               ├── shooting (ENUM: Y/N)
                               ├── day_of_week (ENUM)
                               ├── occurred_on_date, year, month, hour
                               └── lat, long
```

---

## Project Structure

```
crime_reports_db/
├── README.md
└── sql/
    ├── 01_schema.sql        # Schema, tables, types, indexes, comments
    ├── 02_load_data.sql     # Staging table → CSV load → normalized inserts
    ├── 03_user_roles.sql    # RBAC: roles, users, grants, revokes
    ├── 04_analysis_queries.sql  # 12 analytical queries
    ├── 05_views.sql         # 5 reusable reporting views
    └── 06_sample_data.sql   # Test data (use without the full CSV)
```

---

## Setup Instructions

### Prerequisites
- PostgreSQL 13+
- `psql` CLI or pgAdmin

### 1. Create the Database
```sql
CREATE DATABASE boston_crimes;
\c boston_crimes
```

### 2. Run Scripts in Order
```bash
psql -U postgres -d boston_crimes -f sql/01_schema.sql
psql -U postgres -d boston_crimes -f sql/06_sample_data.sql   # for testing
# OR (with real data):
# update the CSV path in 02_load_data.sql, then:
psql -U postgres -d boston_crimes -f sql/02_load_data.sql
psql -U postgres -d boston_crimes -f sql/03_user_roles.sql
psql -U postgres -d boston_crimes -f sql/05_views.sql
```

### 3. Run Analysis Queries
```bash
psql -U postgres -d boston_crimes -f sql/04_analysis_queries.sql
```

### 4. Get the Dataset
Download from Kaggle:  
👉 https://www.kaggle.com/datasets/ankkur13/boston-crime-data  
Place the CSV at the path specified in `02_load_data.sql`.

---

## Key Analysis Questions Answered

1. **How have crime incidents trended year over year?**
2. **What are the top 10 most common offenses in Boston?**
3. **Which district has the highest crime rate and shooting rate?**
4. **What hours of the day and days of the week are most dangerous?**
5. **Which streets are shooting hotspots?**
6. **What is the 3-month rolling average trend in crime?**
7. **Which offense categories dominate each year?**
8. **What is the peak crime hour per district?**

---

## Sample Query: Peak Crime Hours by District

```sql
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
```

---

## Security Design

| Role | Permissions |
|---|---|
| `readonly_group` | `SELECT` on all tables in `crimes` schema |
| `readwrite_group` | `SELECT`, `INSERT`, `UPDATE`, `DELETE` + sequences |
| `analyst_user` | Member of `readonly_group` |
| `engineer_user` | Member of `readwrite_group` |
| `PUBLIC` | Revoked from schema and database |

---

## Potential Extensions

- **Python integration**: Connect with `psycopg2` or `SQLAlchemy`, automate data loads
- **Visualization**: Export query results to Pandas → Matplotlib / Seaborn heatmaps
- **Geospatial**: Use PostGIS extension to enable spatial queries on `lat`/`long` columns
- **Partitioning**: Partition the `reports` table by `year` for performance at scale
- **Stored Procedures**: Automate monthly refresh jobs

---

## Dataset Source

- **Boston Crime Incident Reports** – Kaggle  
  https://www.kaggle.com/datasets/ankkur13/boston-crime-data  
  Original data published by the Boston Police Department.

---

*Built as part of a data engineering portfolio. Inspired by the Dataquest SQL Projects series.*
