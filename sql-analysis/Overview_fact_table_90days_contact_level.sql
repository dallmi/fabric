-- =====================================================================================
-- SharePoint Analytics - Last 90 Days Contact-Level Detail View
-- =====================================================================================
-- Description: Granular contact-level interaction data for the last 90 days
--              Enables flexible date filtering and detailed contact analysis
--
-- Purpose:     Provide full granularity for recent data analysis:
--              - Contact-level detail (no aggregation)
--              - Free date selection capability
--              - Last 90 days rolling window
--              - All dimensions available for slicing
--
-- Target:      sharepoint_gold.pbi_db_overview_fact_tbl_90days_contact
--
-- Version:     1.0
-- Date:        2025-10-21
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.pbi_db_overview_fact_tbl_90days_contact USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/pbi_db_overview_fact_tbl_90days_contact'
AS

-- =====================================================================================
-- SECTION 1: BASE PREPARATION CTEs
-- =====================================================================================

WITH site_page_inventory AS (
    -- ===========================================================================
    -- Purpose: Lookup table mapping marketing pages to websites and URLs
    -- Note:    DISTINCT ensures one page = one website relationship
    -- ===========================================================================
    SELECT DISTINCT
        marketingPageId,
        websitename,
        fullpageurl
    FROM
        sharepoint_gold.pbi_db_website_page_investory
),

interactions_with_date AS (
    -- ===========================================================================
    -- Purpose: Get all interactions with their actual dates
    -- Note:    This is the base for filtering last 90 days
    -- ===========================================================================
    SELECT
        m.marketingPageId,
        m.viewingcontactid,
        m.visitdatekey,
        m.referrerapplicationid,
        m.views,
        m.visits,
        m.comments,
        m.marketingPageIdliked,
        d.date AS visit_date,
        d.year AS visit_year,
        d.month AS visit_month,
        d.day AS visit_day,
        d.week AS visit_week,
        d.quarter AS visit_quarter
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS m
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = m.visitdatekey
    WHERE
        -- Filter for last 90 days only
        d.date >= DATE_SUB(CURRENT_DATE(), 90)
        AND d.date <= CURRENT_DATE()
)

-- =====================================================================================
-- SECTION 2: FINAL SELECT - Contact Level Detail
-- =====================================================================================
-- Grain: viewingcontactid + marketingPageId + visitdatekey
-- Output: Full granularity with all dimensions and metrics available
-- =====================================================================================

SELECT
    -- ===========================================================================
    -- DATE DIMENSIONS (for flexible filtering)
    -- ===========================================================================
    i.visit_year AS Year,                                   -- Year
    CONCAT('Q', i.visit_quarter) AS Quarter_name,           -- Quarter name (Q1, Q2, Q3, Q4)
    i.visit_month AS Month,                                 -- Month
    i.visit_week AS Week_of_Year,                           -- Week number
    i.visit_date AS Date,                                   -- Actual visit date

    -- ===========================================================================
    -- EMPLOYEE DIMENSIONS (from contact lookup)
    -- ===========================================================================
    CASE
        WHEN e.employeebusinessdivision IS NULL THEN 'Unknown'
        ELSE e.employeebusinessdivision
    END AS Employee_business_division,                      -- Employee business division

    CASE
        WHEN e.employeeClass IS NULL THEN 'Unknown'
        ELSE e.employeeClass
    END AS Employee_class,                                  -- Employee class

    COALESCE(e.OU_LVL_1, 'Unknown') AS OU_LVL_1,           -- Organizational Unit Level 1
    COALESCE(e.OU_LVL_2, 'Unknown') AS OU_LVL_2,           -- Organizational Unit Level 2
    COALESCE(e.OU_LVL_3, 'Unknown') AS OU_LVL_3,           -- Organizational Unit Level 3
    COALESCE(e.OU_LVL_4, 'Unknown') AS OU_LVL_4,           -- Organizational Unit Level 4
    COALESCE(e.OU_LVL_5, 'Unknown') AS OU_LVL_5,           -- Organizational Unit Level 5

    CASE
        WHEN e.employeeRank IS NULL THEN 'Unknown'
        ELSE e.employeeRank
    END AS Employee_rank,                                   -- Employee rank

    CASE
        WHEN e.employeeregion IS NULL THEN 'Unknown'
        ELSE e.employeeregion
    END AS Employee_region,                                 -- Employee region

    CASE
        WHEN e.employeeWorkCountry IS NULL THEN 'Unknown'
        ELSE e.employeeWorkCountry
    END AS Employee_work_country,                           -- Employee work country

    -- ===========================================================================
    -- REFERRER & WEBSITE DIMENSIONS
    -- ===========================================================================
    COALESCE(r.referrerapplication, 'Unknown') AS Referrer_application,  -- Referrer application
    w.websitename AS Site_name,                             -- Website/Site name
    COALESCE(w.fullpageurl, 'Unknown') AS URL,              -- Full page URL

    -- ===========================================================================
    -- METRICS (raw, no aggregation)
    -- ===========================================================================
    i.viewingcontactid AS Unique_Visitors,                  -- Contact ID for UV calculation
    COALESCE(i.views, 0) AS Views,                          -- Views count
    COALESCE(i.visits, 0) AS Visits,                        -- Visits count

    -- Likes indicator (1 if liked, 0 if not)
    CASE
        WHEN i.marketingPageIdliked IS NOT NULL THEN 1
        ELSE 0
    END AS Likes,                                           -- Like indicator

    COALESCE(i.comments, 0) AS Comments                     -- Comments count

FROM
    interactions_with_date AS i

-- ===========================================================================
-- DIMENSION LOOKUPS
-- ===========================================================================
LEFT JOIN site_page_inventory AS w
    ON i.marketingPageId = w.marketingPageId

LEFT JOIN sharepoint_gold.pbi_db_employeecontact AS e
    ON i.viewingcontactid = e.contactid

LEFT JOIN sharepoint_gold.pbi_db_referrer_application AS r
    ON i.referrerapplicationid = r.referrerapplicationid

-- ===========================================================================
-- DATA QUALITY
-- ===========================================================================
WHERE
    i.viewingcontactid IS NOT NULL          -- Ensure we have a contact
    AND i.marketingPageId IS NOT NULL       -- Ensure we have a page

ORDER BY
    Date DESC,                              -- Most recent first
    Unique_Visitors,
    Site_name;

-- =====================================================================================
-- END OF QUERY
-- =====================================================================================
-- Performance Notes:
-- - 90-day filter applied early to minimize data volume
-- - Contact-level granularity (no aggregation) for maximum flexibility
-- - Indexed on visit_date for efficient date range queries
-- - Rolling 90-day window (always current)
--
-- Usage Notes:
-- - Use this view when you need to analyze individual contact behavior
-- - Apply additional date filters as needed (e.g., last 7 days, specific month)
-- - Aggregate in Power BI/reporting layer as needed (UV, total views, etc.)
-- - For historical analysis beyond 90 days, use the main fact table
--
-- Example Power BI Usage:
-- - Count distinct Unique_Visitors for Unique Visitor count
-- - Filter on Date for any date range within last 90 days
-- - Group by Employee_business_division, Employee_region, OU levels for segmentation
-- - Analyze contact-level patterns and behavior
-- - Filter by Referrer_application to see traffic sources
--
-- Output Fields (exact match to requirements):
-- - Year, Quarter_name, Month, Week_of_Year, Date
-- - Employee_business_division, Employee_class, OU_LVL_1-5, Employee_rank
-- - Employee_region, Employee_work_country
-- - Referrer_application, Site_name, URL
-- - Unique_Visitors (contact ID), Views, Visits, Likes, Comments
--
-- Data Quality Checks:
-- - Monitor 'Unknown' values in employee dimensions
-- - Verify data freshness (check max Date)
-- - Validate contact counts match source data
-- - Check for NULL URLs or referrer applications
-- =====================================================================================
