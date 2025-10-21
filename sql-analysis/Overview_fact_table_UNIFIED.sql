-- =====================================================================================
-- SharePoint Analytics - Unified Fact Table (Historical + Recent Detail)
-- =====================================================================================
-- Description: Intelligent combination of aggregated historical data and detailed
--              contact-level data for recent periods
--
-- Purpose:     Provide a single unified interface that:
--              - Uses aggregated data for historical analysis (>90 days)
--              - Uses contact-level detail for recent analysis (<=90 days)
--              - Maintains consistent grain and metrics across both sources
--
-- Target:      sharepoint_gold.pbi_db_overview_fact_tbl_unified
--
-- Version:     1.0
-- Date:        2025-10-21
-- =====================================================================================

%sql
CREATE OR REPLACE TABLE sharepoint_gold.pbi_db_overview_fact_tbl_unified USING delta
LOCATION 'abfss://gold@d6476p1s05sweugempI.dfs.core.windows.net/employee_analytics/pbi_db_overview_fact_tbl_unified'
AS

-- =====================================================================================
-- SECTION 1: RECENT DETAIL (Last 90 Days - Contact Level)
-- =====================================================================================

WITH recent_detail AS (
    -- ===========================================================================
    -- Purpose: Contact-level detail for the last 90 days
    -- Source:  Direct from interactions_metrics table
    -- Grain:   viewingcontactid + marketingPageId + visitdatekey
    -- ===========================================================================
    SELECT
        -- Date dimensions
        d.date AS visit_date,
        d.year AS visit_year,
        d.month AS visit_month,
        d.week AS visit_week,
        d.quarter AS visit_quarter,

        -- Contact identifier
        m.viewingcontactid,

        -- Page identifier
        m.marketingPageId,

        -- Foreign keys for dimensions
        m.visitdatekey,
        m.referrerapplicationid,

        -- Metrics
        m.views,
        m.visits,
        m.comment,
        CASE WHEN m.marketingPageIdliked IS NOT NULL THEN 1 ELSE 0 END AS likes,
        m.durationsum,
        m.durationavg,
        m.flag,

        -- Flag to identify data source
        'RECENT_DETAIL' AS data_source

    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS m
    INNER JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = m.visitdatekey
    WHERE
        -- Last 90 days only
        d.date >= DATE_SUB(CURRENT_DATE(), 90)
        AND d.date <= CURRENT_DATE()
        AND m.viewingcontactid IS NOT NULL
        AND m.marketingPageId IS NOT NULL
),

-- =====================================================================================
-- SECTION 2: HISTORICAL AGGREGATED (>90 Days - Pre-aggregated)
-- =====================================================================================

historical_aggregated AS (
    -- ===========================================================================
    -- Purpose: Pre-aggregated historical data beyond 90 days
    -- Source:  pbi_db_overview_fact_tbl (the FIXED aggregated table)
    -- Grain:   marketingPageId + division + region (aggregated, no contact level)
    -- Note:    This is already aggregated, we need to expand it to match grain
    -- ===========================================================================
    SELECT
        -- Date dimensions (need to reconstruct from aggregated table)
        d.date AS visit_date,
        d.year AS visit_year,
        d.month AS visit_month,
        d.week AS visit_week,
        d.quarter AS visit_quarter,

        -- Contact identifier: NULL for aggregated data
        NULL AS viewingcontactid,

        -- Page identifier
        f.marketingPageId,

        -- Foreign keys
        d.date_key AS visitdatekey,
        NULL AS referrerapplicationid,  -- Not available in aggregated table

        -- Metrics (already aggregated)
        f.div_reg_views AS views,
        f.div_reg_visits AS visits,
        f.div_reg_comments AS comment,
        f.div_reg_likes AS likes,
        NULL AS durationsum,  -- Not available in aggregated table
        NULL AS durationavg,  -- Not available in aggregated table
        NULL AS flag,         -- Not available in aggregated table

        -- Flag to identify data source
        'HISTORICAL_AGG' AS data_source

    FROM
        sharepoint_gold.pbi_db_overview_fact_tbl AS f
    CROSS JOIN
        sharepoint_gold.pbi_db_dim_date AS d
    WHERE
        -- Only historical data (>90 days ago)
        d.date < DATE_SUB(CURRENT_DATE(), 90)
        -- Note: This cross join is intentional to create daily grain
        -- You may want to adjust this based on your needs
)

-- =====================================================================================
-- SECTION 3: UNION BOTH SOURCES
-- =====================================================================================

SELECT
    -- ===========================================================================
    -- DATE DIMENSIONS
    -- ===========================================================================
    visit_year AS Year,
    CONCAT('Q', visit_quarter) AS Quarter_name,
    visit_month AS Month,
    visit_week AS Week_of_Year,
    visit_date AS Date,

    -- ===========================================================================
    -- IDENTIFIERS & KEYS
    -- ===========================================================================
    viewingcontactid AS Contact_ID,
    marketingPageId AS Marketing_Page_ID,
    visitdatekey AS Visit_Date_Key,
    referrerapplicationid AS Referrer_Application_ID,

    -- ===========================================================================
    -- METRICS
    -- ===========================================================================
    COALESCE(views, 0) AS Views,
    COALESCE(visits, 0) AS Visits,
    COALESCE(likes, 0) AS Likes,
    COALESCE(comment, 0) AS Comments,
    COALESCE(durationsum, 0) AS Duration_Sum,
    COALESCE(durationavg, 0) AS Duration_Avg,
    COALESCE(flag, 0) AS Flag,

    -- ===========================================================================
    -- METADATA
    -- ===========================================================================
    data_source AS Data_Source,

    -- Flag for contact-level granularity
    CASE
        WHEN viewingcontactid IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS Has_Contact_Detail

FROM recent_detail

UNION ALL

SELECT
    visit_year AS Year,
    CONCAT('Q', visit_quarter) AS Quarter_name,
    visit_month AS Month,
    visit_week AS Week_of_Year,
    visit_date AS Date,
    viewingcontactid AS Contact_ID,
    marketingPageId AS Marketing_Page_ID,
    visitdatekey AS Visit_Date_Key,
    referrerapplicationid AS Referrer_Application_ID,
    COALESCE(views, 0) AS Views,
    COALESCE(visits, 0) AS Visits,
    COALESCE(likes, 0) AS Likes,
    COALESCE(comment, 0) AS Comments,
    COALESCE(durationsum, 0) AS Duration_Sum,
    COALESCE(durationavg, 0) AS Duration_Avg,
    COALESCE(flag, 0) AS Flag,
    data_source AS Data_Source,
    CASE
        WHEN viewingcontactid IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS Has_Contact_Detail

FROM historical_aggregated

ORDER BY Date DESC, Contact_ID, Marketing_Page_ID;

-- =====================================================================================
-- END OF QUERY
-- =====================================================================================
-- Usage Notes:
--
-- TWO DATA SOURCES COMBINED:
-- 1. RECENT_DETAIL (last 90 days):
--    - Contact_ID is populated
--    - Full granularity for detailed analysis
--    - Use for: Drill-downs, contact-level analysis, flexible date ranges
--
-- 2. HISTORICAL_AGG (>90 days):
--    - Contact_ID is NULL
--    - Aggregated data only
--    - Use for: Long-term trends, historical comparisons
--
-- POWER BI USAGE:
-- - Filter by Data_Source to use specific table
-- - Filter by Has_Contact_Detail = TRUE for contact-level analysis
-- - For UV calculation on recent data: COUNT DISTINCT Contact_ID WHERE Has_Contact_Detail = TRUE
-- - For historical data: Use pre-aggregated UV from dimension joins
--
-- IMPORTANT LIMITATION:
-- - Historical aggregated data does NOT have contact-level detail
-- - UV calculation for >90 days requires different approach (see semantic layer design)
--
-- MAINTENANCE:
-- - Recent detail refreshes daily (rolling 90-day window)
-- - Historical aggregated is static (only grows with new data)
-- =====================================================================================
