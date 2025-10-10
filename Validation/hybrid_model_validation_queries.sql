-- =====================================================================================
-- Hybrid Model Data Volume Validation Queries
-- =====================================================================================
-- Purpose: Validate feasibility of hybrid approach with:
--          - 2 specific sites with page-level detail (13 months)
--          - All sites aggregated without page granularity (13 months)
--
-- Business Context:
--   - 740 total sites, 40k pages, 130k employees
--   - Target 2 sites have ~5k pages combined
--   - Need 13 months of data
--   - Current full dataset: 60M rows over 2 years
--
-- IMPORTANT FIX: The investory table has multiple rows per marketingPageId (includes
--                visitdatekey), so we must use DISTINCT to get unique page->website mapping
-- =====================================================================================

-- =====================================================================================
-- QUERY 1: Identify Top Sites by Interaction Volume
-- =====================================================================================
-- Purpose: Identify which 2 sites to include for page-level detail
-- Use: Business may want highest-volume sites or specific strategic sites

WITH page_to_website AS (
    -- Deduplicate investory table to get unique page->website mapping
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
    page_to_website AS w
    ON f.marketingPageId = w.marketingPageId
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
GROUP BY
    w.websitename
ORDER BY
    total_interactions DESC
LIMIT 20;


-- =====================================================================================
-- QUERY 2: Row Count for 2 Specific Sites (Page-Level Detail) - 13 Months
-- =====================================================================================
-- Purpose: Estimate row count for page-level detail on 2 sites
-- Action: Replace 'Site1' and 'Site2' with actual site names from Query 1

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    '2 Sites - Page Level Detail' AS data_type,
    COUNT(*) AS row_count,
    COUNT(DISTINCT f.viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT f.marketingPageId) AS distinct_pages,
    COUNT(DISTINCT w.websitename) AS distinct_sites
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
LEFT JOIN
    page_to_website AS w
    ON f.marketingPageId = w.marketingPageId
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
    AND w.websitename IN ('Site1', 'Site2');  -- REPLACE WITH ACTUAL SITE NAMES


-- =====================================================================================
-- QUERY 3: Row Count for All Sites Aggregated (No Page Granularity) - 13 Months
-- =====================================================================================
-- Purpose: Estimate row count for aggregated data across all sites
-- Note: Aggregated at website + division + region + date level (NO marketingPageId)

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
),
aggregated_data AS (
    SELECT
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        f.visitdatekey,
        d.date,
        -- Keep contact ID for UV calculation in Power BI
        f.viewingcontactid,
        -- Aggregate metrics
        SUM(f.views) AS views,
        SUM(f.visits) AS visits,
        SUM(f.comments) AS comments,
        -- Count likes (deduplicated by contact)
        COUNT(DISTINCT f.marketingPageIdliked) AS likes
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        page_to_website AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
    GROUP BY
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        f.visitdatekey,
        d.date,
        f.viewingcontactid
)
SELECT
    'All Sites - Aggregated (No Page)' AS data_type,
    COUNT(*) AS row_count,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT websitename) AS distinct_sites
FROM aggregated_data;


-- =====================================================================================
-- QUERY 4: Combined Hybrid Model Row Count Estimate
-- =====================================================================================
-- Purpose: Estimate total row count for hybrid approach
-- Action: Replace 'Site1' and 'Site2' with actual site names

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
),
page_level_detail AS (
    -- 2 Sites with full page-level detail
    SELECT
        f.viewingcontactid,
        f.marketingPageId,
        f.marketingPageIdliked,
        f.visitdatekey,
        f.views,
        f.visits,
        f.comments,
        d.date,
        e.employeebusinessdivision,
        e.employeeregion,
        w.websitename,
        'page_detail' AS data_grain
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        page_to_website AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
        AND w.websitename IN ('Site1', 'Site2')  -- REPLACE WITH ACTUAL SITE NAMES
),
all_sites_aggregated AS (
    -- All sites aggregated (no page granularity)
    SELECT
        f.viewingcontactid,
        NULL AS marketingPageId,  -- No page granularity
        f.marketingPageIdliked,
        f.visitdatekey,
        SUM(f.views) AS views,
        SUM(f.visits) AS visits,
        SUM(f.comments) AS comments,
        d.date,
        e.employeebusinessdivision,
        e.employeeregion,
        w.websitename,
        'site_aggregated' AS data_grain
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        page_to_website AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
    GROUP BY
        f.viewingcontactid,
        f.marketingPageIdliked,
        f.visitdatekey,
        d.date,
        e.employeebusinessdivision,
        e.employeeregion,
        w.websitename
)
SELECT
    data_grain,
    COUNT(*) AS row_count
FROM (
    SELECT * FROM page_level_detail
    UNION ALL
    SELECT * FROM all_sites_aggregated
) combined
GROUP BY data_grain

UNION ALL

SELECT
    'TOTAL HYBRID MODEL' AS data_grain,
    COUNT(*) AS row_count
FROM (
    SELECT * FROM page_level_detail
    UNION ALL
    SELECT * FROM all_sites_aggregated
) combined;


-- =====================================================================================
-- QUERY 5: Breakdown by Month - Track Data Growth Over Time
-- =====================================================================================
-- Purpose: Understand data volume patterns by month for capacity planning
-- Note: Using aggregated approach (no page granularity)

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    YEAR(d.date) AS year,
    MONTH(d.date) AS month,
    DATE_TRUNC('MONTH', d.date) AS month_start,
    COUNT(*) AS raw_row_count,
    COUNT(DISTINCT CONCAT(
        w.websitename, '|',
        COALESCE(e.employeebusinessdivision, 'Unknown'), '|',
        COALESCE(e.employeeregion, 'Unknown'), '|',
        f.visitdatekey, '|',
        f.viewingcontactid
    )) AS estimated_aggregated_rows,
    COUNT(DISTINCT f.viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT f.marketingPageId) AS distinct_pages,
    COUNT(DISTINCT w.websitename) AS distinct_sites
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
LEFT JOIN
    sharepoint_gold.pbi_db_employeecontact AS e
    ON f.viewingcontactid = e.contactid
LEFT JOIN
    page_to_website AS w
    ON f.marketingPageId = w.marketingPageId
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
GROUP BY
    YEAR(d.date),
    MONTH(d.date),
    DATE_TRUNC('MONTH', d.date)
ORDER BY
    year DESC,
    month DESC;


-- =====================================================================================
-- QUERY 6: Alternative - Daily Grain Instead of Contact-Level
-- =====================================================================================
-- Purpose: If even aggregated contact-level is too large, consider daily aggregation
-- Trade-off: Loses ability to calculate UV in Power BI, but drastically reduces rows

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
),
daily_aggregated AS (
    SELECT
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        d.date,
        COUNT(DISTINCT f.viewingcontactid) AS unique_visitors,  -- Pre-calculated UV
        SUM(f.views) AS views,
        SUM(f.visits) AS visits,
        SUM(f.comments) AS comments,
        COUNT(DISTINCT f.marketingPageIdliked) AS likes
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        sharepoint_gold.pbi_db_employeecontact AS e
        ON f.viewingcontactid = e.contactid
    LEFT JOIN
        page_to_website AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months
    GROUP BY
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        d.date
)
SELECT
    'Daily Aggregated (No Contact ID)' AS approach,
    COUNT(*) AS estimated_rows,
    COUNT(DISTINCT websitename) AS distinct_sites,
    COUNT(DISTINCT date) AS distinct_days,
    SUM(unique_visitors) AS total_uv_across_all_combinations
FROM daily_aggregated;


-- =====================================================================================
-- EXECUTION INSTRUCTIONS
-- =====================================================================================
-- 1. Run Query 1 first to identify top 2 sites by volume
-- 2. Update 'Site1' and 'Site2' in Queries 2, 4 with actual site names
-- 3. Run Queries 2-6 to validate different hybrid approaches
-- 4. Compare row counts against 10M target
-- 5. If still too large, consider:
--    - Reducing from 13 months to 6-9 months
--    - Using daily grain (Query 6) for aggregated data
--    - Including only 1 site at page-level instead of 2
-- =====================================================================================
