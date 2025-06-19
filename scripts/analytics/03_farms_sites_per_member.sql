-- ==========================================
-- Report: Number of Farms and Sites per Member
-- Source: gold.fct_registration + gold.dim_member
-- Note: Includes members missing from dim_member
-- ==========================================

SELECT
    COALESCE(dm.member_name, fr.dim_member_id) AS member_name_or_id,
    COUNT(DISTINCT fr.dim_farm_id) AS number_of_farms,
    COUNT(DISTINCT fr.dim_site_id) AS number_of_sites
FROM 
    gold.fct_registration fr
LEFT JOIN 
    gold.dim_member dm 
    ON fr.dim_member_id = dm.dim_member_id
GROUP BY
    COALESCE(dm.member_name, fr.dim_member_id)
ORDER BY 
    number_of_farms DESC, 
    number_of_sites DESC;
