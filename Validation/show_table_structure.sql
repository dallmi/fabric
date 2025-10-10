-- =====================================================================================
-- Quick Commands to View Table Structure in Databricks
-- =====================================================================================

-- OPTION 1: DESCRIBE - Shows all columns with data types
-- =====================================================================================
DESCRIBE sharepoint_gold.pbi_db_website_page_investory;


-- OPTION 2: DESCRIBE EXTENDED - Shows more details including location
-- =====================================================================================
-- DESCRIBE EXTENDED sharepoint_gold.pbi_db_website_page_investory;


-- OPTION 3: Show column names only (simple list)
-- =====================================================================================
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'sharepoint_gold'
  AND table_name = 'pbi_db_website_page_investory'
ORDER BY ordinal_position;


-- OPTION 4: Count distinct values per column (helps identify key columns)
-- =====================================================================================
-- Uncomment and run this to see cardinality of each column
/*
SELECT
    'marketingPageId' as column_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT marketingPageId) as distinct_values,
    COUNT(*) - COUNT(DISTINCT marketingPageId) as duplicates
FROM sharepoint_gold.pbi_db_website_page_investory

UNION ALL

SELECT
    'websitename' as column_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT websitename) as distinct_values,
    COUNT(*) - COUNT(DISTINCT websitename) as duplicates
FROM sharepoint_gold.pbi_db_website_page_investory;
*/
