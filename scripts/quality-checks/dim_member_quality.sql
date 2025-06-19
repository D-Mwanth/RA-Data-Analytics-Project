/*
===============================================================================
Data Quality Checks – gold.dim_member
===============================================================================

Objective:
Assess completeness, uniqueness, format adherence, and temporal logic 
to ensure the integrity of `dim_member` records for reliable reporting.

===============================================================================
CHECKS
===============================================================================
*/

-- 1. Completeness of Key Fields
-- Ensure mandatory fields are populated
SELECT 
    SUM(CASE WHEN dim_member_id IS NULL THEN 1 ELSE 0 END) AS null_dim_member_id,
    SUM(CASE WHEN member_id IS NULL THEN 1 ELSE 0 END) AS null_member_id,
    SUM(CASE WHEN tandc_version IS NULL THEN 1 ELSE 0 END) AS null_tandc_version,
    SUM(CASE WHEN date_registered IS NULL THEN 1 ELSE 0 END) AS null_date_registered,
    SUM(CASE WHEN tandc_signdate IS NULL THEN 1 ELSE 0 END) AS null_tandc_signdate,
    SUM(CASE WHEN date_validated IS NULL THEN 1 ELSE 0 END) AS null_date_validated
FROM gold.dim_member;

-- 2. Primary Key Uniqueness
-- Confirm no duplicate dim_member_id values exist
SELECT dim_member_id, COUNT(*) AS duplicate_count
FROM gold.dim_member
GROUP BY dim_member_id
HAVING COUNT(*) > 1;

-- Confirm each member have unique member_id
SELECT member_id, COUNT(*) AS duplicate_count
FROM gold.dim_member
GROUP BY member_id
HAVING COUNT(*) > 1;

-- 3. Source System Consistency
-- Ensure all records originate from a known and trusted source (e.g., RECAP)
SELECT dim_source, COUNT(*) AS record_count
FROM gold.dim_member
GROUP BY dim_source;

-- 4. Member ID Format
-- Must match 'RAM-######' pattern (10 characters, case-sensitive). This will aslo address leading/trailing whitespace
SELECT *
FROM gold.dim_member
WHERE member_id IS NULL
   OR PATINDEX('RAM-[0-9][0-9][0-9][0-9][0-9][0-9]', member_id) != 1
   OR LEN(member_id) != 10;

-- 5. Member Name Format
-- Must match 'Member-#######' pattern (14 characters, case-sensitive). This will aslo address leading/trailing whitespace
SELECT *
FROM gold.dim_member
WHERE member_name IS NULL
   OR PATINDEX('Member-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]', member_name) != 1
   OR LEN(member_name) != 14;

-- 6. tandc_type Completeness for version 6
-- Identify records where terms type is not missing for version 6 <fo imputation purpose>
SELECT *
FROM gold.dim_member
WHERE tandc_version = '6'
  AND tandc_type IS NOT NULL;

-- 7. Country Distribution
-- Detect potential geographic skew in member registration
SELECT country, COUNT(*) AS member_count
FROM gold.dim_member
GROUP BY country
ORDER BY member_count DESC;

-- 8. Verify: Temporal Logic
-- A member should registor first then sign terms and conditions and the they can be validated
SELECT *
FROM gold.dim_member
WHERE 
    date_registered > tandc_signdate
    OR date_validated < tandc_signdate;

--------------------------------------------------------------------------------
-- Findings, Assumptions, Recommendations
--------------------------------------------------------------------------------

/*
Finding:
    1. Completeness:
        - Data of Mandatory field is complete.
    2. Uniquness:
        - No duplicated records in the members dataset.
    3. Source System Consistency:
        - All data was sourced from RACP.
    4. Member ID and Name naming convention:
        - All member_id records adheres to same naming convention and so it the members names
    5. The type of Terms and Conditions version 6 is completely null and cant be infered from the data.
    
    6. Country Distribution:
        - No major skewness observed as data is quite small, however most of members are form india, followed by
        -- Brazil and colombia.
    7. Temporal logic: FAILED
        - From the data we have member `6EAB604DBEDD472379EF7002C68E1FFD` who signed before registoring which does not follow the logic of time.
    
Recommendations:
    - Enforce NOT NULL constraints on all critical fields (e.g., member_id, dates).
    - Enforce uniqueness constraint on `dim_member_id` and `member_id`. one Id is for the data and another one for the member themselves
    - Communicate the absence of type of terms and conditions version 6 with the Manager so he can connect with cross-sectional teamm to discover this type    
    - Ensure all members registration follows the order `date_registered <= tandc_signdate <= date_validated`.
    -- Also connect with upstream teams to inverstigate why the member (ID: 6EAB604DBEDD472379EF7002C68E1FFD) violates the registreation process order.
*/