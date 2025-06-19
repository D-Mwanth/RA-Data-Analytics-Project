/*
===============================================================================
Data Quality Checks – gold.dim_crop
===============================================================================

Objective:
Validate integrity, uniqueness, formatting, and data origin of crop dimension 
records to ensure consistency for analytical and operational usage.

===============================================================================
CHECKS
===============================================================================
*/

-- 1. Primary Key Integrity
-- Ensure no NULLs in crop ID
SELECT COUNT(*) AS null_dim_crop_id
FROM gold.dim_crop
WHERE dim_crop_id IS NULL;

-- 2. Uniqueness of Crop ID
-- Detect duplicate primary key entries
WITH RankedRecords AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY dim_crop_id ORDER BY dim_crop_id) AS row_num
    FROM gold.dim_crop
)
SELECT *
FROM RankedRecords
WHERE row_num > 1;

-- 3. Completeness of Crop Names
-- Ensure crop name is present
SELECT COUNT(*) AS null_crop_name_count
FROM gold.dim_crop
WHERE crop IS NULL;

-- 4. Duplicate Crop Names: Each crop name should be unique
-- Case- and space-insensitive duplication
SELECT LOWER(TRIM(crop)) AS normalized_crop_name, COUNT(*) AS occurrences
FROM gold.dim_crop
GROUP BY LOWER(TRIM(crop))
HAVING COUNT(*) > 1;

-- 5. Formatting Check
-- Detect crop names with unnecessary whitespace
SELECT crop
FROM gold.dim_crop
WHERE crop <> TRIM(crop);

-- 6. Source System Consistency
-- All records should come from the same known source (e.g., 'SystemA')
SELECT DISTINCT dim_source, COUNT(*) AS record_count
FROM gold.dim_crop
GROUP BY dim_source;


/*
===============================================================================
                   Finding and Recommendation
===============================================================================
Finding:
    All checks passed, thus the dim_crop data is of good quality.

Recommedations:
1. Primary Key Integrity:
   - Enforce `NOT NULL` and `UNIQUE` constraints on `dim_crop_id`.
   - Eliminate duplicate records based on the primary key.

2. Crop Name Validity:
   - Ensure all crop names are non-null and properly trimmed.
   - Remove duplicates after normalizing case and whitespace.

3. Consistent Naming Standards:
   - Define a naming convention or approved list for `crop` values to support 
     standard reporting and integration.

4. Source System Consistency:
   - If data shows to come from untrusted source other than RECAP consider connecting with upstream team,
   -- data engineers to be clarified before you proceed.
   - Investigate and remediate records from unexpected systems to avoid data drift.

5. Load Date (Optional):
   - Though `dim_load_date` is system-generated, consider tracking anomalies 
     during ETL for auditing purposes.

===============================================================================
*/
