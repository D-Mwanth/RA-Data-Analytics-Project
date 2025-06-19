/*
===============================================================================
Data Quality Checks – gold.dim_farm
===============================================================================

Objective:
Validate the integrity, formatting, and business-rule compliance of records 
in `dim_farm` to ensure fitness for reporting, analytics, and modeling.

===============================================================================
CHECKS
===============================================================================
*/

-- 1. Primary Key Completeness & Uniqueness
-- Ensure no NULLs or duplicates in dim_farm_id
SELECT COUNT(*) AS null_farm_id_count
FROM gold.dim_farm
WHERE dim_farm_id IS NULL;

-- 2. Uniqueness
-- Check for duplicate primary keys
SELECT dim_farm_id, COUNT(*) AS duplicate_count
FROM gold.dim_farm
GROUP BY dim_farm_id
HAVING COUNT(*) > 1;

-- 3: Farm Name Formatting: farm_name follows naming convention 'Farm 123456'
-- Pattern must match: 'Farm ' + 6 digits (length = 11 characters)
SELECT *
FROM gold.dim_farm
WHERE farm_name IS NULL
   OR PATINDEX('Farm [0-9][0-9][0-9][0-9][0-9][0-9]', farm_name) != 1
   OR LEN(farm_name) != 11;

-- 4. Area Sanity Checks: Area can never be a negative value
SELECT *
FROM gold.dim_farm
WHERE TRY_CAST(totalareainha AS FLOAT) < 0;

-- 5. Outliers: Compair max Farm area for smallholder and min area of large farm
-- Ensure no smallholder exceeds the smallest large farm
WITH AreaParsed AS (
    SELECT 
        farmtype,
        TRY_CAST(totalareainha AS FLOAT) AS area
    FROM gold.dim_farm
    WHERE totalareainha IS NOT NULL
)
SELECT 
    (SELECT MAX(area) FROM AreaParsed WHERE farmtype = 'Smallholder') AS max_smallholder_area,
    (SELECT MIN(area) FROM AreaParsed WHERE farmtype = 'Large') AS min_large_area;

-- 6. Temporal Consistency
-- Check that createdon does not come after updatedon
SELECT *
FROM gold.dim_farm
WHERE createdon > updatedon;

-- 7. Placeholder / Imputed Dates
-- Detect use of default date values ('01/01/2000')
SELECT *
FROM gold.dim_farm
WHERE createdon = '01/01/2000' OR updatedon = '01/01/2000';

-- Insight: All such records also have NULL for firstyearofcertification

-- 8. Date Format Consistency
-- Check if createdon is in valid ISO 8601 format (YYYY-MM-DD or compatible)
SELECT *
FROM gold.dim_farm
WHERE TRY_CONVERT(datetime, createdon, 126) IS NULL 
    OR TRY_CONVERT(datetime, updatedon, 126) IS NULL;


/*
===============================================================================
                    Findings, Assumptions, Recommendation
===============================================================================

Findings:
    1. Primary Keys Completeness: PASSED <no null values in the primary key>
    2. Primary Keys Uniquness: PASSED <no duplicated firms>
    3. Farm Naming covention compliance: PASSED
    4. Farm area with negavtive size: PASSED <no farm with negative area>
    5. Outliers on the area size: FAILED <max smallholder land area=, min largeholder area=1>
    6. Temporal Consitency: NEUTRAL <no tangible relationship between the createdon and updatedon fields>
    7. '01/01/2000' appear to be default date value used for imputing null values for date field.
    8. Date format consistency: PASSED <all dates adhere to same formating>
Assumptions:
    - A primary key cannot be null and need to be unique.
    - A piece of land cant have a negative area
    - No small farmholder should have a large piece of land than the large farm holders.
    - Date a record was created should be in past compaired to the date the record was updated, to ensure temporal consistency.

Recommedation:
    - For the failing check such as one for the outliers, try communicating with the team 
    -- to come up with best solution for handling them.
    - Also, define and enforce expected business rules for temporal relationships.
===============================================================================
*/
