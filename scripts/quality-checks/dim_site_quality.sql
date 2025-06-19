/*
===============================================================================
Data Quality Checks – gold.dim_site
===============================================================================

Objective:
Evaluate the completeness, uniqueness, format adherence, and temporal logic 
of records in `dim_site` to ensure readiness for analytics and reporting.

===============================================================================
CHECKS
===============================================================================
*/

-- 1. Completeness of Fields
-- Ensure critical fields are not NULL
SELECT 
    SUM(CASE WHEN dim_site_id IS NULL THEN 1 ELSE 0 END) AS null_dim_site_id,
    SUM(CASE WHEN on_sitehousing IS NULL THEN 1 ELSE 0 END) AS null_on_sitehousing,
    SUM(CASE WHEN verificationlevel IS NULL THEN 1 ELSE 0 END) AS null_verificationlevel,
    SUM(CASE WHEN is_certification_scope IS NULL THEN 1 ELSE 0 END) AS null_is_certification_scope,
    SUM(CASE WHEN createdon IS NULL THEN 1 ELSE 0 END) AS null_createdon,
    SUM(CASE WHEN updatedon IS NULL THEN 1 ELSE 0 END) AS null_updatedon
FROM gold.dim_site;

-- 2. Uniqueness
-- Check for duplicate primary keys
SELECT dim_site_id, COUNT(*) AS duplicate_count
FROM gold.dim_site
GROUP BY dim_site_id
HAVING COUNT(*) > 1;

-- 3. Data Source Validation
-- Check if all records originate from a trusted system
SELECT DISTINCT dim_source, COUNT(*) AS record_count
FROM gold.dim_site
GROUP BY dim_source;

-- 4. Site Name Formatting
-- Must match 'Site 123456' exactly: case-sensitive, 1 space, 6 digits
SELECT *
FROM gold.dim_site
WHERE site_name IS NULL
   OR PATINDEX('Site [0-9][0-9][0-9][0-9][0-9][0-9]', site_name) != 1
   OR LEN(site_name) != 11;

-- 5. Placeholder / Imputed Dates
-- Identify use of default values like '01/01/00' which maps to 2000-01-01
SET DATEFORMAT MDY;

SELECT COUNT(*) AS placeholder_date_count
FROM gold.dim_site
WHERE CAST(createdon AS DATE) = '01/01/00'
   OR CAST(updatedon AS DATE) = '01/01/00';

-- 6. Temporal Logic
-- Ensure createdon does not come after updatedon
SELECT *
FROM gold.dim_site
WHERE createdon > updatedon;

-- Note: Reverse check to confirm correct ordering
SELECT *
FROM gold.dim_site
WHERE createdon <= updatedon;

-- 7. Whitespace & Case Check in Site Name (Optional)
-- Check for names with unexpected leading/trailing spaces
SELECT *
FROM gold.dim_site
WHERE site_name LIKE ' %' OR site_name LIKE '% ';

--------------------------------------------------------------------------------
-- Finding, Recommendations
--------------------------------------------------------------------------------

/*
Finding:
    1. Data Completeness:
        - Key field such as firm Id is complete but there is null values recorded in other columns
    2. Site Name Standardization:
        - All site names are enforced to same standard, 'Site ######'.
    3. Data Source Validation:
        - Data come from two sources, System and Recap, however, data from SYSTEM source is a single record,
        -- probably a wrong record, and we may need to consult whether to disgard it or not.
 
    -- 7. Future Readiness:
    -- - Introduce historization or slowly changing dimensions (SCD) for temporal tracking.
    -- - Capture change logs where applicable.
*/
