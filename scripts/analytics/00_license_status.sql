/*
================================================================
        Count of Granted, Expired, and Not Granted Licenses
================================================================

Script Purpose:
    This script calculates the number of licenses in the following categories:
    - Granted
    - Expired
    - Not Granted

Exclusions:
    - Licenses with a `NULL` status (i.e., unknown status) are excluded from the count.

Special Handling:
    - Licenses referenced in the fact table but missing from the `dim_license` table
      are assumed to be `Granted` and included in the results.
      
    Justification:
    - These records represent crop registrations tied to active licensing activity.
      Their presence implies that a valid license was issued, even if the corresponding
      entry in `dim_license` is missing. Hence, they are treated as Granted.

Assumptions:
    - License status is determined strictly based on whether the license was ultimately granted.
    - No data imputation has been applied to missing statuses; therefore, this output may not reflect
      the true distribution. It represents how the results would look assuming the available data is complete.
*/

SELECT 
    license_status,
    COUNT(*) AS number_of_licenses
FROM (
    -- Licenses from dim_license (with status)
    SELECT license_status
    FROM gold.dim_license

    UNION ALL

    -- Licenses in fact table that are missing from dim_license — assume "Granted"
    SELECT 'Granted' AS license_status
    FROM gold.fct_registration f
    WHERE NOT EXISTS (
        SELECT 1
        FROM gold.dim_license d
        WHERE d.dim_license_id = f.dim_license_id
    )
) AS combined
WHERE license_status IS NOT NULL
GROUP BY license_status
ORDER BY number_of_licenses DESC;

/*
Failed assumption:
    1. If the license signdate is between 2021 and 2022, and license status is missing then can be considered Granted
    Why Failed:
        - There case of licenses which were signed within that durationa and status is Expired.
*/

-- =============================================================================
-- Drop and Create a View
-- =============================================================================

IF OBJECT_ID('gold.vw_license_status_counts', 'V') IS NOT NULL
    DROP VIEW gold.vw_license_status_counts;
GO

CREATE VIEW gold.vw_license_status_counts AS
SELECT 
    license_status,
    COUNT(*) AS number_of_licenses
FROM (
    -- Status from dim_license table
    SELECT license_status
    FROM gold.dim_license

    UNION ALL

    -- Assume "Granted" for registrations missing from dim_license
    SELECT 'Granted' AS license_status
    FROM gold.fct_registration f
    WHERE NOT EXISTS (
        SELECT 1
        FROM gold.dim_license d
        WHERE d.dim_license_id = f.dim_license_id
    )
) AS combined
WHERE license_status IS NOT NULL
GROUP BY license_status;
GO