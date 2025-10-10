-- =====================================================================================
-- Diagnostic Queries for pbi_db_website_page_investory Table
-- =====================================================================================
-- Purpose: Understand the structure and identify potential issues causing
--          inflated row counts in Query 1
-- =====================================================================================

-- =====================================================================================
-- DIAGNOSTIC 1: Check for duplicates on marketingPageId
-- =====================================================================================
-- If a marketingPageId appears multiple times, the JOIN will multiply rows

SELECT
    'Duplicate Check' AS check_type,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    COUNT(*) - COUNT(DISTINCT marketingPageId) AS duplicate_count,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT marketingPageId) THEN 'OK - No Duplicates'
        ELSE 'PROBLEM - Duplicates Found!'
    END AS status
FROM
    sharepoint_gold.pbi_db_website_page_investory;


-- =====================================================================================
-- DIAGNOSTIC 2: Show sample rows with duplicate marketingPageId
-- =====================================================================================
-- This will show which pages have multiple entries and why

SELECT
    marketingPageId,
    COUNT(*) AS row_count,
    COUNT(DISTINCT websitename) AS distinct_websites,
    -- Show all distinct values in columns that might cause duplicates
    COLLECT_SET(websitename) AS all_websites
FROM
    sharepoint_gold.pbi_db_website_page_investory
GROUP BY
    marketingPageId
HAVING
    COUNT(*) > 1
ORDER BY
    row_count DESC
LIMIT 20;


-- =====================================================================================
-- DIAGNOSTIC 3: Check table structure - what columns exist?
-- =====================================================================================
-- This helps identify if there's a 'referrer' or other columns causing issues

DESCRIBE sharepoint_gold.pbi_db_website_page_investory;


-- =====================================================================================
-- DIAGNOSTIC 4: Sample data from the table
-- =====================================================================================
-- Show first 20 rows to understand the data structure

SELECT *
FROM sharepoint_gold.pbi_db_website_page_investory
LIMIT 20;


-- =====================================================================================
-- DIAGNOSTIC 5: Count pages per website
-- =====================================================================================
-- This should show the actual distribution

SELECT
    websitename,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    COUNT(*) AS total_rows,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT marketingPageId) THEN 'OK'
        ELSE 'Duplicates Present'
    END AS status
FROM
    sharepoint_gold.pbi_db_website_page_investory
GROUP BY
    websitename
ORDER BY
    total_rows DESC
LIMIT 20;


-- =====================================================================================
-- DIAGNOSTIC 6: Test Query 1 with DISTINCT fix
-- =====================================================================================
-- This is Query 1 but using DISTINCT in the subquery to prevent multiplication

WITH deduplicated_inventory AS (
    SELECT DISTINCT
        marketingPageId,
        websitename
    FROM
        sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    w.websitename,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT f.marketingPageId) AS distinct_pages,
    COUNT(DISTINCT f.viewingcontactid) AS unique_visitors,
    MIN(d.date) AS earliest_interaction,
    MAX(d.date) AS latest_interaction
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
LEFT JOIN
    deduplicated_inventory AS w
    ON f.marketingPageId = w.marketingPageId
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
GROUP BY
    w.websitename
ORDER BY
    total_interactions DESC
LIMIT 20;
