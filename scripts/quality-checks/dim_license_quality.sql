/*
===============================================================================
Data Quality Checks – gold.dim_license
===============================================================================

Objective:
Evaluate completeness, formatting, temporal sequencing, and logical consistency 
of licensing data in `gold.dim_license` to ensure it supports certification 
compliance reporting, downstream auditing, and analytics.

===============================================================================
CHECKS
===============================================================================
*/

-- 1. Completeness Check: Critical Fields
-- Ensure no NULLs in core identifiers or source metadata
SELECT 
    SUM(CASE WHEN dim_license_id IS NULL THEN 1 ELSE 0 END) AS null_dim_license_id,
    SUM(CASE WHEN dim_source IS NULL THEN 1 ELSE 0 END) AS null_dim_source,
    SUM(CASE WHEN license_id IS NULL THEN 1 ELSE 0 END) AS null_license_id,
    SUM(CASE WHEN scheme_owner IS NULL THEN 1 ELSE 0 END) AS null_scheme_owner
FROM gold.dim_license;

-- Completeness Check: Remaining Fields
SELECT 
    SUM(CASE WHEN dim_load_date IS NULL THEN 1 ELSE 0 END) AS null_dim_load_date,
    SUM(CASE WHEN certificationoption IS NULL THEN 1 ELSE 0 END) AS null_certificationoption,
    SUM(CASE WHEN gmr_download_status IS NULL THEN 1 ELSE 0 END) AS null_gmr_download_status,
    SUM(CASE WHEN date_requirements_viewed IS NULL THEN 1 ELSE 0 END) AS null_date_requirements_viewed,
    SUM(CASE WHEN date_selfassessment_uploaded IS NULL THEN 1 ELSE 0 END) AS null_date_selfassessment_uploaded,
    SUM(CASE WHEN date_gmr_uploaded IS NULL THEN 1 ELSE 0 END) AS null_date_gmr_uploaded,
    SUM(CASE WHEN contract_sign_status IS NULL THEN 1 ELSE 0 END) AS null_contract_sign_status,
    SUM(CASE WHEN date_contract_signed IS NULL THEN 1 ELSE 0 END) AS null_date_contract_signed,
    SUM(CASE WHEN license_type IS NULL THEN 1 ELSE 0 END) AS null_license_type,
    SUM(CASE WHEN license_status IS NULL THEN 1 ELSE 0 END) AS null_license_status,
    SUM(CASE WHEN license_standard IS NULL THEN 1 ELSE 0 END) AS null_license_standard,
    SUM(CASE WHEN start_date_license IS NULL THEN 1 ELSE 0 END) AS null_start_date_license,
    SUM(CASE WHEN end_date_license IS NULL THEN 1 ELSE 0 END) AS null_end_date_license,
    SUM(CASE WHEN original_end_date IS NULL THEN 1 ELSE 0 END) AS null_original_end_date,
    SUM(CASE WHEN legalagreementchecked IS NULL THEN 1 ELSE 0 END) AS null_legalagreementchecked,
    SUM(CASE WHEN license_year IS NULL THEN 1 ELSE 0 END) AS null_license_year
FROM gold.dim_license;


-- 2. ID Formatting Compliance: license_id must follow the standard format
-- Format: 'RALI##-########' (e.g., RALI01-12345678), total length = 15 characters
-- This also indirectly verifies case, structure, and absence of whitespace
SELECT *
FROM gold.dim_license
WHERE license_id IS NULL
   OR license_id NOT LIKE 'RALI[0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
   OR LEN(license_id) != 15;

-- 3. Temporal Logic: License must only become active after contract is signed
-- Ensures licenses are not activated before agreement is formalized
SELECT *
FROM gold.dim_license
WHERE date_contract_signed > start_date_license;

-- 4. Temporal Logic: License start date must be before end date
-- Prevents invalid durations or reversed license periods
SELECT *
FROM gold.dim_license
WHERE TRY_CONVERT(DATE, start_date_license) > TRY_CONVERT(DATE, end_date_license);

-- 5. Duration Validity: License should not start and end on the same day
-- One known violation: `DA9D0D7F745D83AC610BEF8331BE1692`
SELECT *
FROM gold.dim_license
WHERE start_date_license = end_date_license;

-- 6. Logical Consistency: All 'Granted' licenses must have legal agreement checked
SELECT *
FROM gold.dim_license
WHERE license_status = 'Granted' 
  AND legalagreementchecked != 'TRUE';

-- 7. Ownership Verification: Ensure all licenses are issued under Rainforest Alliance
-- Expected: All `scheme_owner` values should be 'RA'
SELECT *
FROM gold.dim_license
WHERE scheme_owner != 'RA';

-- 8. Check: Requirements must be viewed before uploading self-assessment
SELECT *
FROM gold.dim_license
WHERE date_requirements_viewed > date_selfassessment_uploaded;

-- 9. Check: 'Group Of Small Farms' licenses must not be fully signed before GRM is uploaded
-- Ensures proper documentation steps are followed before contractual commitment
SELECT *
FROM gold.dim_license
WHERE certificationoption = 'Group Of Small Farms' 
  AND date_gmr_uploaded IS NULL 
  AND contract_sign_status = 'BothConfirmed';

-- 10. Check: Documentation must precede contract signing
-- Ensures members view requirements and upload self-assessment *before* contract is signed
-- Note: Some records show contracts being signed before documentation — likely a process violation
-- If `Granted` licenses lack contract dates, consider imputing from `start_date_license`
SELECT *
FROM gold.dim_license
WHERE 
    TRY_CONVERT(DATE, date_requirements_viewed) > TRY_CONVERT(DATE, date_contract_signed)
    OR TRY_CONVERT(DATE, date_selfassessment_uploaded) > TRY_CONVERT(DATE, date_contract_signed);

/*
===============================================================================
                    Finding, Assumption, Recommedation
===============================================================================

Finding:
    1. Data Completeness:
        -- Completeness of critical field: : PASSED
        -- Completeness of none critical field: FAILED <Missing values are  present>
    2. Naming Conventions Adherance: PASSED
        -- All license id names adheres to a common naming convention <`RALI##-########`>.
    3. Temporal Logic:
        -- License must only become active after contract is signed:  FAILED <Some license have start date which was recorded before were signed>
        -- License start date must be before end date: PASSED
    4. Duration Validity:
        - License should not start and end on the same day: FAILED
            -- License with `DA9D0D7F745D83AC610BEF8331BE1692` ID started and ended on the same day
            Investigation shows, this dates are probably out of unkeen imputation of the date column with 1/1/1990 as default value.
    
    5. Logical Consistency:
        - All 'Granted' licenses must have legal agreement checked: PASSED
    6. License Ownership Verification:
        - All licenses are issued under Rainforest Alliance, < 'RA'>: PASSED
    7. Self-Assessment Flow Check:
        - Requirements must be viewed before uploading self-assessment: FAILED
            -- Seems there is no such relationship.
    8. Certification Logic:
        - 'Group Of Small Farms' licenses must not be fully signed before GRM is uploaded: FAILED

            -- Two problematic records found: 
            --   - `72391C94078BC7FD5B80356A8E607903`: viewed requirements and uploaded self-assessment — treat GRM upload as data entry omission.
            --   - `ABE4EBB6D178654CEB0B03FF9F659A2A`: did not upload self-assessment — violates flow.
    9. Temporal Validation:
        - Documentation must precede contract signing: FAILED

RECOMMENDATIONS:

1. Enforce NOT NULL constraints for critical:
   - Columns: `dim_license_id`, `license_id`, and `dim_source` should be required to prevent incomplete license records.
   - For the rest of the field, consider systematic imputation, potentially involving the Data Engineering team if source data access is required.

2. Standardize `license_id` format at ingestion:
   - Use regex pattern checks or transformation logic to ensure values strictly follow the `RALI##-########` format.
   - Trim and uppercase `license_id` values as needed.

3. Introduce a data rule preventing licenses from becoming active (`start_date_license`) before contract signing (`date_contract_signed`):
   - This can be implemented either in ETL or upstream systems.

4. Review any licenses where `start_date_license = end_date_license`:
   - Unless explicitly supported by business rules, these licenses should be rejected or flagged as data entry issues.

5. Require `legalagreementchecked = TRUE` before a license can reach `Granted` status:
   - Add validation to ensure all legal conditions are met prior to license issuance.

6. Apply ownership validation:
   - Ensure `scheme_owner = 'RA'` unless new business logic supports multiple owners.

7. Enforce sequence of documentation:
   - `date_requirements_viewed` must occur before `date_selfassessment_uploaded`, especially for calculating certification risk profiles.

8. Validate group certification logic:
   - For `certificationoption = 'Group Of Small Farms'`, ensure `date_gmr_uploaded` is populated before both parties confirm contract.
   - Investigate exceptions: 
       - `72391C94078BC7FD5B80356A8E607903` may be a one-off data entry lapse.
       - `ABE4EBB6D178654CEB0B03FF9F659A2A` represents a genuine process break.

===============================================================================
*/