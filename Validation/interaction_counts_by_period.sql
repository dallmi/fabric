-- =====================================================================================
-- Total Interaction Counts by Time Period
-- =====================================================================================
-- Purpose: Get total row counts from interactions_metrics table for different periods
-- =====================================================================================

-- =====================================================================================
-- OPTION 1: Simple counts for 13 months and 6 months
-- =====================================================================================

SELECT
    '13 months' AS period,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    MIN(d.date) AS earliest_date,
    MAX(d.date) AS latest_date
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)  -- Last 13 months (395 days)

UNION ALL

SELECT
    '6 months' AS period,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    MIN(d.date) AS earliest_date,
    MAX(d.date) AS latest_date
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -180)  -- Last 6 months (180 days)

UNION ALL

SELECT
    'All time' AS period,
    COUNT(*) AS total_interactions,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    MIN(d.date) AS earliest_date,
    MAX(d.date) AS latest_date
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey;


-- =====================================================================================
-- OPTION 2: Just the raw counts (super fast)
-- =====================================================================================
-- Use this if you just need the basic numbers quickly

SELECT
    COUNT(CASE WHEN d.date >= DATE_ADD(CURRENT_DATE(), -395) THEN 1 END) AS interactions_13_months,
    COUNT(CASE WHEN d.date >= DATE_ADD(CURRENT_DATE(), -180) THEN 1 END) AS interactions_6_months,
    COUNT(*) AS interactions_all_time
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey;


-- =====================================================================================
-- OPTION 3: Detailed breakdown with metrics
-- =====================================================================================

WITH period_stats AS (
    SELECT
        d.date,
        f.*
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
)
SELECT
    '13 months' AS period,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    SUM(views) AS total_views,
    SUM(visits) AS total_visits,
    SUM(comments) AS total_comments,
    COUNT(DISTINCT marketingPageIdliked) AS total_likes,
    MIN(date) AS from_date,
    MAX(date) AS to_date,
    DATEDIFF(MAX(date), MIN(date)) AS days_span
FROM
    period_stats
WHERE
    date >= DATE_ADD(CURRENT_DATE(), -395)

UNION ALL

SELECT
    '6 months' AS period,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT viewingcontactid) AS unique_visitors,
    COUNT(DISTINCT marketingPageId) AS distinct_pages,
    SUM(views) AS total_views,
    SUM(visits) AS total_visits,
    SUM(comments) AS total_comments,
    COUNT(DISTINCT marketingPageIdliked) AS total_likes,
    MIN(date) AS from_date,
    MAX(date) AS to_date,
    DATEDIFF(MAX(date), MIN(date)) AS days_span
FROM
    period_stats
WHERE
    date >= DATE_ADD(CURRENT_DATE(), -180);


-- =====================================================================================
-- Notes:
-- =====================================================================================
-- - 13 months = 395 days (13 * 30.42 days average)
-- - 6 months = 180 days (6 * 30 days)
-- - Current date is calculated as of query execution time
-- - All counts are based on the interactions_metrics fact table
-- =====================================================================================
