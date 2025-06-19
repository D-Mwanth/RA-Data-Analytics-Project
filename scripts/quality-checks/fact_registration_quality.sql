-- ========================================================================================
-- Data Quality Validation: gold.fct_registration
-- ========================================================================================

-- 1. Completeness Check: Ensure no NULLs in fact table fields
-- Result: No NULLs found (data is complete)
SELECT 
    SUM(CASE WHEN fact_registration_id IS NULL THEN 1 ELSE 0 END) AS null_fact_registration_id,
    SUM(CASE WHEN fact_source IS NULL THEN 1 ELSE 0 END) AS null_fact_source,
    SUM(CASE WHEN fact_load_date IS NULL THEN 1 ELSE 0 END) AS null_fact_load_date,
    SUM(CASE WHEN dim_member_id IS NULL THEN 1 ELSE 0 END) AS null_dim_member_id,
    SUM(CASE WHEN dim_license_id IS NULL THEN 1 ELSE 0 END) AS null_dim_license_id,
    SUM(CASE WHEN dim_crop_id IS NULL THEN 1 ELSE 0 END) AS null_dim_crop_id,
    SUM(CASE WHEN dim_site_id IS NULL THEN 1 ELSE 0 END) AS null_dim_site_id,
    SUM(CASE WHEN dim_farm_id IS NULL THEN 1 ELSE 0 END) AS null_dim_farm_id,
    SUM(CASE WHEN date_crop_registered IS NULL THEN 1 ELSE 0 END) AS null_date_crop_registered
FROM gold.fct_registration;

-- 2. Uniquness checks: PASSED
SELECT fact_registration_id, COUNT(*) AS duplicate_count
FROM gold.fct_registration
GROUP BY fact_registration_id
HAVING COUNT(*) > 1;

-- 3. Source Verification: Confirm all data originates from RACP (passed)
SELECT DISTINCT fact_source
FROM gold.fct_registration;

-- 4. Referential Integrity: Foreign key presence in dimension tables

-- a. Missing dim_member_id references
SELECT f.*
FROM gold.fct_registration f
LEFT JOIN gold.dim_member d ON f.dim_member_id = d.dim_member_id
WHERE d.dim_member_id IS NULL;

-- b. Missing dim_license_id references
SELECT f.*
FROM gold.fct_registration f
LEFT JOIN gold.dim_license d ON f.dim_license_id = d.dim_license_id
WHERE d.dim_license_id IS NULL;

-- c. Missing dim_crop_id references <all reference keys exist in the dim_crop table>
SELECT f.*
FROM gold.fct_registration f
LEFT JOIN gold.dim_crop d ON f.dim_crop_id = d.dim_crop_id
WHERE d.dim_crop_id IS NULL;

-- d. Missing dim_site_id references
SELECT f.*
FROM gold.fct_registration f
LEFT JOIN gold.dim_site d ON f.dim_site_id = d.dim_site_id
WHERE d.dim_site_id IS NULL;

-- e. Missing dim_farm_id references
SELECT f.*
FROM gold.fct_registration f
LEFT JOIN gold.dim_farm d ON f.dim_farm_id = d.dim_farm_id
WHERE d.dim_farm_id IS NULL;

-- 5. Format Consistency: Ensure all `date_crop_registered` values are valid dates
SELECT *
FROM gold.fct_registration
WHERE TRY_CONVERT(DATETIME, date_crop_registered) IS NULL;

-- 6. Temporal Range Check: Identify earliest and latest crop registration dates
SELECT
    MIN(date_crop_registered) AS earliest_crop_registration,
    MAX(date_crop_registered) AS latest_crop_registration
FROM gold.fct_registration;

-- ========================================================================================
-- Finding, Assumption, and Recommendation:
-- ========================================================================================

-- Finding:
-- Some foreign key values in `gold.fct_registration` (e.g., `dim_member_id`, `dim_license_id`, 
-- `dim_site_id`, and `dim_farm_id`) do not match current entries in the corresponding 
-- dimension tables. Crop registrations span from '2021-04-26' to '2022-09-05'.

-- Assumption:
-- These unmatched foreign key values are still valid despite being absent from current dimension tables, 
-- as they are linked to active crop registrations. They likely exist in historical or archived data 
-- not yet incorporated into the `gold` schema.

-- Recommendation:
-- Explore historical backups or upstream systems to recover the missing dimension records. 
-- If relevant, implement Slowly Changing Dimensions (SCD)
-- to preserve historical values required for fact table consistency.
-- ========================================================================================