-- =====================================================================
-- STEP 6: ANALYTICS LAYER — JOIN ALL CLEAN TABLES + COMPUTE FINAL KPIs
-- MySQL version
-- =====================================================================
-- This is the set of tables Power BI will actually connect to.
--
-- NOTE ON YEAR COVERAGE MISMATCH (same caveat as the BigQuery version):
-- fund_release covers 2019-20 to 2023-24
-- houses_sanctioned covers 2017-18 to 2019-20
-- physical_progress is a single 2022 snapshot (no year axis)
-- pmuy_connections covers 2018 to 2023
-- These do NOT fully overlap — handled via two separate output tables.
-- =====================================================================

USE pmay_analytics;


-- ---------------------------------------------------------------------
-- 6A. YEAR-ON-YEAR VIEW (only valid for the one overlapping year: 2019-20)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS pmay_g_yearly_kpis;

CREATE TABLE pmay_g_yearly_kpis AS
SELECT
    f.state_name,
    f.scheme_year,
    f.fund_released_crore,
    h.houses_sanctioned,
    h.is_known_data_gap,
    CASE
        WHEN h.houses_sanctioned IS NULL OR h.houses_sanctioned = 0 THEN NULL
        ELSE ROUND(f.fund_released_crore / h.houses_sanctioned, 4)
    END AS cost_per_house_crore
FROM clean_fund_release f
INNER JOIN clean_houses_sanctioned h
    ON f.state_name = h.state_name
    AND f.scheme_year = h.scheme_year
ORDER BY f.state_name, f.scheme_year;

-- This will only return rows for 2019-20, since that's the only year
-- present in BOTH source tables — expected, not a bug.


-- ---------------------------------------------------------------------
-- 6B. STATE-LEVEL MASTER SUMMARY (the main dashboard table)
-- ---------------------------------------------------------------------

-- First, pre-compute the national average/stddev completion % once,
-- since MySQL doesn't support correlated scalar subqueries inside a
-- CASE expression as cleanly as BigQuery — easier to materialize first.
DROP TABLE IF EXISTS _tmp_national_benchmarks;

CREATE TABLE _tmp_national_benchmarks AS
SELECT
    AVG(completion_pct_of_target) AS avg_completion,
    STDDEV(completion_pct_of_target) AS stddev_completion
FROM clean_physical_progress;


-- MySQL note: dim_states has duplicate clean names by design (e.g.
-- both 'Orissa' and 'Odisha' raw rows map to the same clean name
-- 'Odisha'). BigQuery's QUALIFY ROW_NUMBER()... = 1 deduplicated this
-- inline; MySQL has no QUALIFY, so we dedupe dim_states into a temp
-- table FIRST using a subquery with ROW_NUMBER (MySQL 8.0+ supports
-- window functions, just not QUALIFY).
DROP TABLE IF EXISTS _tmp_dim_states_deduped;

CREATE TABLE _tmp_dim_states_deduped AS
SELECT state_name_clean, state_category, region
FROM (
    SELECT
        state_name_clean,
        state_category,
        region,
        ROW_NUMBER() OVER (PARTITION BY state_name_clean ORDER BY state_name_raw) AS rn
    FROM dim_states
) ranked
WHERE rn = 1;


DROP TABLE IF EXISTS state_level_summary;

CREATE TABLE state_level_summary AS
SELECT
    d.state_name_clean AS state_name,
    d.state_category,
    d.region,

    -- Housing outcomes (cumulative, as of 2022 snapshot)
    p.target_houses,
    p.sanctioned_houses_cumulative,
    p.completed_houses_cumulative,
    p.completion_pct_of_target,
    p.completion_pct_of_sanctioned,

    -- Budget (total released, multi-year)
    ft.total_fund_released_crore,
    ft.avg_annual_fund_released_crore,

    -- Cost efficiency: crore spent per completed house, all-time
    CASE
        WHEN p.completed_houses_cumulative IS NULL OR p.completed_houses_cumulative = 0 THEN NULL
        ELSE ROUND(ft.total_fund_released_crore / p.completed_houses_cumulative, 4)
    END AS cost_per_completed_house_crore,

    -- Ujjwala
    cl.pmuy_connections_2023,
    cl.pmuy_new_connections_2023,
    cl.pmuy_yoy_growth_pct_2023,

    -- Performance tiering vs national average + stddev (pre-computed above)
    CASE
    WHEN p.completion_pct_of_target IS NULL THEN 'Data Unavailable'
    WHEN p.completion_pct_of_target < (nb.avg_completion - nb.stddev_completion) THEN 'Critical'
    WHEN p.completion_pct_of_target < nb.avg_completion THEN 'Below Average'
    WHEN p.completion_pct_of_target < (nb.avg_completion + nb.stddev_completion) THEN 'Above Average'
    ELSE 'High Performer'
END AS performance_tier

FROM _tmp_dim_states_deduped d
LEFT JOIN clean_physical_progress p ON d.state_name_clean = p.state_name
LEFT JOIN (
    SELECT
        state_name,
        SUM(fund_released_crore) AS total_fund_released_crore,
        AVG(fund_released_crore) AS avg_annual_fund_released_crore
    FROM clean_fund_release
    GROUP BY state_name
) ft ON d.state_name_clean = ft.state_name
LEFT JOIN (
    SELECT state_name,
           cumulative_connections AS pmuy_connections_2023,
           new_connections_this_year AS pmuy_new_connections_2023,
           yoy_growth_pct AS pmuy_yoy_growth_pct_2023
    FROM clean_pmuy_connections
    WHERE scheme_year = 2023
) cl ON d.state_name_clean = cl.state_name
CROSS JOIN _tmp_national_benchmarks nb
ORDER BY state_name;

-- Clean up temp tables
DROP TABLE IF EXISTS _tmp_national_benchmarks;
DROP TABLE IF EXISTS _tmp_dim_states_deduped;

CREATE INDEX idx_sls_state ON state_level_summary (state_name);


-- ---------------------------------------------------------------------
-- NATIONAL UJJWALA "LAST-MILE" CALLOUT (single fixed figure, cited)
-- ---------------------------------------------------------------------
-- This is NOT derived from row-level data — state-wise refill data is
-- not publicly available. This is a single national statistic from
-- parliamentary/PIB reporting, stored as a reference table so Power BI
-- can display it as a labeled callout card rather than a computed metric.

DROP TABLE IF EXISTS national_ujjwala_refill_note;

CREATE TABLE national_ujjwala_refill_note AS
SELECT
    11800000 AS beneficiaries_zero_refills_national,
    9000000  AS beneficiaries_refused_refill_high_price_national,
    'Parliamentary / PIB reporting on PMUY implementation (cumulative, national level). State-wise breakdown not publicly available — included as a single contextual figure, not row-level data.' AS source_note;

