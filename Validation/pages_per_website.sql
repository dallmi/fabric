-- =====================================================================================
-- Pages Per Website Analysis
-- =====================================================================================
-- Purpose: Count the number of distinct pages for each website
-- =====================================================================================

SELECT
    websitename,
    COUNT(DISTINCT marketingPageId) AS page_count
FROM
    sharepoint_gold.pbi_db_website_page_inventory
GROUP BY
    websitename
ORDER BY
    page_count DESC;
