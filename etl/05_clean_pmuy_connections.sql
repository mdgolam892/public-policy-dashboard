-- =====================================================================
-- STEP 5: CLEAN & UNPIVOT — PMUY (UJJWALA) LPG CONNECTIONS, 2018-2023 — MySQL
-- =====================================================================
-- IMPORTANT DATA NOTE:
-- These figures are CUMULATIVE connection counts as of each year.
-- This means:
--   - "new connections in year Y" = value(Y) - value(Y-1)
--   - the raw value itself = total connections ever issued, up to year Y
--
-- MYSQL NOTE: window functions (LAG, OVER PARTITION BY) ARE supported
-- in MySQL 8.0+ — this part is actually identical to the BigQuery
-- version. If you're on MySQL 5.7 or earlier, this will fail; check
-- your version with: SELECT VERSION();
-- =====================================================================

USE pmay_analytics;

DROP TABLE IF EXISTS clean_pmuy_connections;

CREATE TABLE clean_pmuy_connections AS
WITH unpivoted AS (
    SELECT
        d.state_name_clean AS state_name,
        2018 AS scheme_year,
        CASE WHEN r.`2018` REGEXP '^[0-9]+$' THEN CAST(r.`2018` AS UNSIGNED) ELSE NULL END AS cumulative_connections
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw   -- note extra space in this file's column name
    WHERE d.state_name_clean IS NOT NULL

    UNION ALL

    SELECT d.state_name_clean, 2019,
        CASE WHEN r.`2019` REGEXP '^[0-9]+$' THEN CAST(r.`2019` AS UNSIGNED) ELSE NULL END
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw
    WHERE d.state_name_clean IS NOT NULL

    UNION ALL

    SELECT d.state_name_clean, 2020,
        CASE WHEN r.`2020` REGEXP '^[0-9]+$' THEN CAST(r.`2020` AS UNSIGNED) ELSE NULL END
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw
    WHERE d.state_name_clean IS NOT NULL

    UNION ALL

    SELECT d.state_name_clean, 2021,
        CASE WHEN r.`2021` REGEXP '^[0-9]+$' THEN CAST(r.`2021` AS UNSIGNED) ELSE NULL END
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw
    WHERE d.state_name_clean IS NOT NULL

    UNION ALL

    SELECT d.state_name_clean, 2022,
        CASE WHEN r.`2022` REGEXP '^[0-9]+$' THEN CAST(r.`2022` AS UNSIGNED) ELSE NULL END
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw
    WHERE d.state_name_clean IS NOT NULL

    UNION ALL

    SELECT d.state_name_clean, 2023,
        CASE WHEN r.`2023` REGEXP '^[0-9]+$' THEN CAST(r.`2023` AS UNSIGNED) ELSE NULL END
    FROM raw_pmuy_connections r
    LEFT JOIN dim_states d ON TRIM(r.`State / UT`) = d.state_name_raw
    WHERE d.state_name_clean IS NOT NULL
)

SELECT
    state_name,
    scheme_year,
    cumulative_connections,

    -- New connections issued in this specific year (vs previous year)
    CAST(cumulative_connections AS SIGNED) - CAST(LAG(cumulative_connections) OVER (
        PARTITION BY state_name ORDER BY scheme_year
    )AS SIGNED) AS new_connections_this_year,

    -- YoY growth rate of cumulative base
    CASE
        WHEN LAG(cumulative_connections) OVER (PARTITION BY state_name ORDER BY scheme_year) IS NULL
          OR LAG(cumulative_connections) OVER (PARTITION BY state_name ORDER BY scheme_year) = 0
        THEN NULL
        ELSE ROUND(
            (CAST(cumulative_connections AS SIGNED) - CAST(LAG(cumulative_connections) OVER (PARTITION BY state_name ORDER BY scheme_year)AS SIGNED))
            / CAST(LAG(cumulative_connections) OVER (PARTITION BY state_name ORDER BY scheme_year)AS SIGNED) * 100
        , 2)
    END AS yoy_growth_pct

FROM unpivoted
ORDER BY state_name, scheme_year;

CREATE INDEX idx_cpc_state_year ON clean_pmuy_connections (state_name, scheme_year);
