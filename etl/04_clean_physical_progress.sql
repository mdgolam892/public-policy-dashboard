-- =====================================================================
-- STEP 4 (FIXED): CLEAN — PHYSICAL PROGRESS — MySQL
-- =====================================================================
-- BUG FIX: The raw file has SEPARATE rows for "Dadra and Nagar Haveli"
-- and "Daman and Diu" (two UTs that merged into one in 2020). Both map
-- to the same clean state name, but without aggregation, this produces
-- TWO rows with the same clean name instead of one combined row —
-- which then duplicates downstream in state_level_summary.
--
-- FIX: GROUP BY state_name_clean and SUM the numeric columns after
-- the rename, so pre-merger UTs are correctly combined into one row.
-- =====================================================================

USE pmay_analytics;

DROP TABLE IF EXISTS clean_physical_progress;

CREATE TABLE clean_physical_progress AS
SELECT
    d.state_name_clean AS state_name,
    DATE('2022-07-01')  AS snapshot_date,

    SUM(
        CASE WHEN r.`MoRD Target` REGEXP '^[0-9]+$' THEN CAST(r.`MoRD Target` AS UNSIGNED) ELSE 0 END
    ) AS target_houses,

    SUM(
        CASE WHEN r.`Sanctions Out of GEO Tagged` REGEXP '^[0-9]+$' THEN CAST(r.`Sanctions Out of GEO Tagged` AS UNSIGNED) ELSE 0 END
    ) AS sanctioned_houses_cumulative,

    SUM(
        CASE WHEN r.`Completed` REGEXP '^[0-9]+$' THEN CAST(r.`Completed` AS UNSIGNED) ELSE 0 END
    ) AS completed_houses_cumulative

FROM raw_physical_progress r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL
GROUP BY d.state_name_clean;          -- <<< THE FIX: aggregates pre-merger UT rows

-- Add the derived completion percentage columns (unchanged from before)
ALTER TABLE clean_physical_progress
    ADD COLUMN completion_pct_of_target DECIMAL(6,2),
    ADD COLUMN completion_pct_of_sanctioned DECIMAL(6,2);

UPDATE clean_physical_progress
SET
    completion_pct_of_target = CASE
        WHEN target_houses IS NULL OR target_houses = 0 THEN NULL
        ELSE ROUND(completed_houses_cumulative / target_houses * 100, 2)
    END,
    completion_pct_of_sanctioned = CASE
        WHEN sanctioned_houses_cumulative IS NULL OR sanctioned_houses_cumulative = 0 THEN NULL
        ELSE ROUND(completed_houses_cumulative / sanctioned_houses_cumulative * 100, 2)
    END;

CREATE INDEX idx_cpp_state ON clean_physical_progress (state_name);

-- ---------------------------------------------------------------------
-- Verify the fix: should now return exactly 1 row, with SUMMED values
-- (6763+68=6831 target, 5536+47=5583 sanctioned, 2158+13=2171 completed)
-- ---------------------------------------------------------------------
-- SELECT * FROM clean_physical_progress
-- WHERE state_name = 'Dadra and Nagar Haveli and Daman and Diu';
