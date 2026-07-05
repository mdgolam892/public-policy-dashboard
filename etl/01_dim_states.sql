-- =====================================================================
-- STEP 1: STATE NAME STANDARDIZATION (DIMENSION TABLE) — MySQL version
-- =====================================================================
-- Purpose: Government files often use inconsistent state naming
-- (e.g. "Odisha" vs "Orissa", "NCT of Delhi" vs "Delhi", trailing
-- footnote markers like "Bihar*"). This table is the single source
-- of truth that every raw table joins against to standardize names.
--
-- Run this ONCE in MySQL Workbench to create the dimension table,
-- then re-run only if you spot a new unmapped variant in raw files.
--
-- MYSQL DIFFERENCE FROM BIGQUERY:
-- No native UNNEST(ARRAY<STRUCT>) syntax in MySQL, so we use a plain
-- multi-row INSERT instead.
-- =====================================================================

USE pmay_analytics;

DROP TABLE IF EXISTS dim_states;

CREATE TABLE dim_states (
    state_name_raw   VARCHAR(100),
    state_name_clean VARCHAR(100),
    state_category    VARCHAR(10),
    region             VARCHAR(30)
);

INSERT INTO dim_states (state_name_raw, state_name_clean, state_category, region) VALUES
('Andaman and Nicobar Islands', 'Andaman and Nicobar Islands', 'UT',    'North East & Islands'),
('Andhra Pradesh',              'Andhra Pradesh',              'State', 'South'),
('Arunachal Pradesh',           'Arunachal Pradesh',           'State', 'North East'),
('Assam',                       'Assam',                       'State', 'North East'),
('Bihar',                       'Bihar',                       'State', 'East'),
('Chandigarh',                  'Chandigarh',                  'UT',    'North'),
('Chhattisgarh',                'Chhattisgarh',                'State', 'Central'),
('Dadra and Nagar Haveli and Daman and Diu', 'Dadra and Nagar Haveli and Daman and Diu', 'UT', 'West'),
('Daman and Diu',               'Dadra and Nagar Haveli and Daman and Diu', 'UT', 'West'),  -- pre-merger name
('Dadra and Nagar Haveli',      'Dadra and Nagar Haveli and Daman and Diu', 'UT', 'West'),  -- pre-merger name
('Delhi',                       'Delhi',                       'UT',    'North'),
('NCT of Delhi',                'Delhi',                       'UT',    'North'),           -- variant
('Goa',                         'Goa',                         'State', 'West'),
('Gujarat',                     'Gujarat',                     'State', 'West'),
('Haryana',                     'Haryana',                     'State', 'North'),
('Himachal Pradesh',            'Himachal Pradesh',            'State', 'North'),
('Jammu and Kashmir',           'Jammu and Kashmir',           'UT',    'North'),
('Jharkhand',                   'Jharkhand',                   'State', 'East'),
('Karnataka',                   'Karnataka',                   'State', 'South'),
('Kerala',                      'Kerala',                      'State', 'South'),
('Ladakh',                      'Ladakh',                      'UT',    'North'),
('Lakshadweep',                 'Lakshadweep',                 'UT',    'North East & Islands'),
('Madhya Pradesh',              'Madhya Pradesh',              'State', 'Central'),
('Maharashtra',                 'Maharashtra',                 'State', 'West'),
('Manipur',                     'Manipur',                     'State', 'North East'),
('Meghalaya',                   'Meghalaya',                   'State', 'North East'),
('Mizoram',                     'Mizoram',                     'State', 'North East'),
('Nagaland',                    'Nagaland',                    'State', 'North East'),
('Odisha',                      'Odisha',                      'State', 'East'),
('Orissa',                      'Odisha',                      'State', 'East'),             -- old spelling
('Puducherry',                  'Puducherry',                  'UT',    'South'),
('Pondicherry',                 'Puducherry',                  'UT',    'South'),             -- old spelling
('Punjab',                      'Punjab',                       'State', 'North'),
('Rajasthan',                   'Rajasthan',                    'State', 'North'),
('Sikkim',                      'Sikkim',                       'State', 'North East'),
('Tamil Nadu',                  'Tamil Nadu',                   'State', 'South'),
('Telangana',                   'Telangana',                    'State', 'South'),
('Tripura',                     'Tripura',                      'State', 'North East'),
('Uttar Pradesh',               'Uttar Pradesh',                'State', 'North'),
('Uttarakhand',                 'Uttarakhand',                  'State', 'North'),
('West Bengal',                 'West Bengal',                  'State', 'East');

-- Add an index on the raw name since every cleaning script joins on it
CREATE INDEX idx_state_raw ON dim_states (state_name_raw);


-- ---------------------------------------------------------------------
-- QA CHECK: run this after loading raw tables to catch unmapped names
-- ---------------------------------------------------------------------
-- SELECT DISTINCT r.`State/UT` AS unmapped_state
-- FROM raw_fund_release r
-- LEFT JOIN dim_states d
--   ON TRIM(r.`State/UT`) = d.state_name_raw
-- WHERE d.state_name_raw IS NULL;
