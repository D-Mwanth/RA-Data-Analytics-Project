/*
====================================================================================
    Report: Count of Active (Granted) Licenses per Crop — with Missing License Logic
====================================================================================

Objective:
- Count active licenses per crop.
- A license is considered Active if:
    1. It exists in `fct_registration` and in `dim_license` AND:
        - `license_status` = 'Granted'
        - OR `license_status` IS NULL (assume best case)
    2. OR it is missing entirely from `dim_license` but exists in `fct_registration`

Why include missing licenses:
- Licenses in the fact table imply active crop registrations.
- Absence in `dim_license` is treated as a data quality issue — assume best-case (i.e., granted and active).
*/

SELECT
    dc.crop AS crop_name,
    COUNT(DISTINCT fr.dim_license_id) AS active_license_count
FROM 
    gold.fct_registration fr
JOIN 
    gold.dim_crop dc 
    ON fr.dim_crop_id = dc.dim_crop_id
LEFT JOIN 
    gold.dim_license dl 
    ON fr.dim_license_id = dl.dim_license_id
WHERE 
    dl.license_status = 'Granted' -- not Expired
    OR dl.license_status IS NULL
    OR dl.dim_license_id IS NULL  -- license missing from dim_license, assume active
GROUP BY 
    dc.crop
ORDER BY 
    active_license_count DESC;


--==================================