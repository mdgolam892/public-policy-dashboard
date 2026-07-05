-- =====================================================================
-- STEP 2: CLEAN & UNPIVOT — FUND RELEASE (PMAY-G) — MySQL version
-- =====================================================================
-- Raw shape: one row per state, one column per year (wide format)
-- Target shape: one row per state PER YEAR (long format)
--
-- MYSQL DIFFERENCE FROM BIGQUERY:
-- MySQL has no native UNPIVOT operator. We replicate it using UNION ALL —
-- one SELECT per year column, all stacked together. More verbose than
-- BigQuery's UNPIVOT(...) syntax, but functionally identical.
-- =====================================================================

USE pmay_analytics;

DROP TABLE IF EXISTS clean_fund_release;

CREATE TABLE clean_fund_release AS
SELECT
    d.state_name_clean AS state_name,
    '2019-20'           AS scheme_year,
    -- CAST(... AS DECIMAL) does NOT fail-safe in MySQL the way BigQuery's
    -- SAFE_CAST does — a genuinely non-numeric string raises a warning,
    -- not an error, and returns NULL. We check explicitly anyway for clarity.
    CASE
        WHEN r.`2019-20` REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(r.`2019-20` AS DECIMAL(12,2))
        ELSE NULL
    END AS fund_released_crore
FROM raw_fund_release r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2020-21',
    CASE WHEN r.`2020-21` REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(r.`2020-21` AS DECIMAL(12,2)) ELSE NULL END
FROM raw_fund_release r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2021-22',
    CASE WHEN r.`2021-22` REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(r.`2021-22` AS DECIMAL(12,2)) ELSE NULL END
FROM raw_fund_release r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2022-23',
    CASE WHEN r.`2022-23` REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(r.`2022-23` AS DECIMAL(12,2)) ELSE NULL END
FROM raw_fund_release r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2023-24',
    CASE WHEN r.`2023-24` REGEXP '^[0-9]+\\.?[0-9]*$' THEN CAST(r.`2023-24` AS DECIMAL(12,2)) ELSE NULL END
FROM raw_fund_release r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL;

CREATE INDEX idx_cfr_state_year ON clean_fund_release (state_name, scheme_year);

-- ---------------------------------------------------------------------
-- Data quality check: flag any NULL fund values after casting
-- ---------------------------------------------------------------------
-- SELECT state_name, scheme_year, fund_released_crore
-- FROM clean_fund_release
-- WHERE fund_released_crore IS NULL;
