# PMAY-G / PMUY Dashboard — Data Pipeline (MySQL version)

## Why MySQL instead of BigQuery

BigQuery's free-trial billing signup failed repeatedly with error `[OR_BACR2_44]` — a known, unresolved Google Cloud issue affecting many users, not something fixable on our end. MySQL (run locally via MySQL Workbench) replicates the exact same architecture and ETL logic without depending on cloud billing setup at all.

**The architecture is unchanged**: Python loads raw files only; SQL does all transformation.

```
Raw CSVs → Python (load only) → MySQL staging tables → SQL ETL → MySQL analytics tables → Power BI
```

---

## Setup — One-Time Steps

### 1. Install MySQL (if not already done)
Download MySQL Community Server + MySQL Workbench from `dev.mysql.com/downloads`. During install, set a root password and remember it.

### 2. Install Python dependencies
```bash
pip install mysql-connector-python pandas sqlalchemy --break-system-packages
```

### 3. Confirm MySQL version supports window functions
Window functions (`LAG`, `ROW_NUMBER() OVER`) require **MySQL 8.0+**. Check your version in Workbench:
```sql
SELECT VERSION();
```
If you're on 5.7 or earlier, you'll need to upgrade — the ETL scripts (steps 5 and 6) depend on window functions.

---

## Pipeline Execution Order

### Step 1 — Load raw CSVs into MySQL (Python)
```bash
cd python/
python load_raw_to_mysql.py --user root --password YOUR_PASSWORD --database pmay_analytics
```
This creates the `pmay_analytics` database if it doesn't exist, and loads all 4 raw CSVs into staging tables (`raw_fund_release`, `raw_houses_sanctioned`, `raw_physical_progress`, `raw_pmuy_connections`).

### Step 2 — Run SQL ETL scripts in MySQL Workbench, IN ORDER
Open each file in Workbench and execute (lightning bolt icon, or Ctrl+Shift+Enter to run the whole script):

1. `sql/01_dim_states.sql` — state name lookup table
2. `sql/02_clean_fund_release.sql` — unpivots fund release wide→long
3. `sql/03_clean_houses_sanctioned.sql` — unpivots houses sanctioned, flags 2018-19 data gap
4. `sql/04_clean_physical_progress.sql` — cleans the single 2022 snapshot
5. `sql/05_clean_pmuy_connections.sql` — unpivots PMUY connections, computes YoY growth
6. `sql/06_analytics_layer.sql` — joins everything into final dashboard tables

### Step 3 — Verify the output tables exist
```sql
USE pmay_analytics;
SHOW TABLES;

SELECT * FROM state_level_summary LIMIT 10;
SELECT * FROM national_ujjwala_refill_note;
```

---

## Key Differences From the BigQuery Version (for your own reference / interview talking points)

| Concept | BigQuery | MySQL |
|---|---|---|
| Unpivoting wide columns | Native `UNPIVOT(...)` | Rewritten as `UNION ALL` of one SELECT per year |
| Safe casting | `SAFE_CAST(x AS FLOAT64)` | `CASE WHEN x REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(x AS DECIMAL) ELSE NULL END` |
| Safe division | `SAFE_DIVIDE(a, b)` | `CASE WHEN b IS NULL OR b = 0 THEN NULL ELSE a/b END` |
| Table replacement | `CREATE OR REPLACE TABLE` | `DROP TABLE IF EXISTS` + `CREATE TABLE` (two statements) |
| Dedup with window function in same query | `QUALIFY ROW_NUMBER() OVER(...) = 1` | No `QUALIFY` — wrap in a subquery, filter `WHERE rn = 1` outside it |
| Window functions (LAG, ROW_NUMBER) | Supported | Supported in MySQL 8.0+ only |
| Namespacing | `project.dataset.table` | `database.table` (one less level) |
| Python client | `google-cloud-bigquery` | `mysql-connector-python` + `sqlalchemy` |

This is a legitimate, talkable engineering decision for an interview: *"I originally designed this in BigQuery, hit a platform-level billing/access issue, and ported the ETL logic to MySQL — which meant rewriting the UNPIVOT logic as UNION ALL and replacing BigQuery's SAFE_* functions with explicit NULL-handling CASE statements."* That's a real, demonstrable skill (knowing multiple SQL dialects), not a downgrade.

---

## Known Data Limitations (unchanged from the BigQuery version)

1. **Year ranges don't fully overlap** across the 4 source files — handled via two output tables (`pmay_g_yearly_kpis` for the one overlapping year 2019-20; `state_level_summary` for the fuller cross-sectional view).
2. **2018-19 houses sanctioned = 0 for all states** in the raw file — flagged via `is_known_data_gap`, not hidden or imputed.
3. **PMUY connection figures are cumulative**, not new-connections-per-year — both interpretations are computed (`cumulative_connections` and `new_connections_this_year`).
4. **Ujjwala refill/adoption data does not exist publicly at state level** — a single cited national statistic is used instead (`national_ujjwala_refill_note` table), explained on the dashboard as a contextual callout, not a queryable metric.

---

## Connecting Power BI to MySQL

1. Power BI Desktop → **Get Data → MySQL Database**
2. Server: `localhost:3306` (or your configured port)
3. Database: `pmay_analytics`
4. Enter your MySQL username/password when prompted
5. Select tables: `state_level_summary`, `national_ujjwala_refill_note`, `pmay_g_yearly_kpis`
6. Load — Power BI's native MySQL connector handles the rest, no gateway needed for a local install
