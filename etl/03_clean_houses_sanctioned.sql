-- =====================================================================
-- STEP 3: CLEAN & UNPIVOT — HOUSES SANCTIONED (PMAY-G, 2017-2020) — MySQL
-- =====================================================================
-- NOTE / DATA QUALITY FLAG:
-- The raw 2018-19 column is entirely zero across every state sampled.
-- This is almost certainly a reporting gap in the source file, NOT a
-- real pause in the scheme. We keep the zero values as-is (don't
-- silently impute) but flag them with is_known_data_gap so downstream
-- queries can choose to exclude 2018-19 from trend analysis.
-- =====================================================================

USE pmay_analytics;

DROP TABLE IF EXISTS clean_houses_sanctioned;

CREATE TABLE clean_houses_sanctioned AS
SELECT
    d.state_name_clean AS state_name,
    '2017-18'           AS scheme_year,
    CASE
        WHEN r.`Houses Sanctioned (Units in Number) - 2017-18` REGEXP '^[0-9]+$'
        THEN CAST(r.`Houses Sanctioned (Units in Number) - 2017-18` AS UNSIGNED)
        ELSE NULL
    END AS houses_sanctioned,
    FALSE AS is_known_data_gap
FROM raw_houses_sanctioned r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2018-19',
    CASE
        WHEN r.`Houses Sanctioned (Units in Number) - 2018-19` REGEXP '^[0-9]+$'
        THEN CAST(r.`Houses Sanctioned (Units in Number) - 2018-19` AS UNSIGNED)
        ELSE NULL
    END,
    -- Flag this year as a known data gap if the value is exactly 0
    (CASE
        WHEN r.`Houses Sanctioned (Units in Number) - 2018-19` REGEXP '^[0-9]+$'
        THEN CAST(r.`Houses Sanctioned (Units in Number) - 2018-19` AS UNSIGNED)
        ELSE NULL
    END = 0) AS is_known_data_gap
FROM raw_houses_sanctioned r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL

UNION ALL

SELECT
    d.state_name_clean, '2019-20',
    CASE
        WHEN r.`Houses Sanctioned (Units in Number) - 2019-20` REGEXP '^[0-9]+$'
        THEN CAST(r.`Houses Sanctioned (Units in Number) - 2019-20` AS UNSIGNED)
        ELSE NULL
    END,
    FALSE
FROM raw_houses_sanctioned r
LEFT JOIN dim_states d ON TRIM(r.`State/UT`) = d.state_name_raw
WHERE d.state_name_clean IS NOT NULL;

CREATE INDEX idx_chs_state_year ON clean_houses_sanctioned (state_name, scheme_year);

-- ---------------------------------------------------------------------
-- Verify the data gap flag worked as expected:
-- ---------------------------------------------------------------------
-- SELECT state_name, scheme_year, houses_sanctioned, is_known_data_gap
-- FROM clean_houses_sanctioned
-- WHERE is_known_data_gap = TRUE;
