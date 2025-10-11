-- =====================================================================================
-- Grain Analysis - Understanding Data Granularity
-- =====================================================================================
-- Purpose: Understand why site-level aggregation only reduces 58% (65M → 27M)
-- =====================================================================================

-- =====================================================================================
-- ANALYSIS 1: What is the actual grain of the fact table?
-- =====================================================================================
-- Check if there are multiple rows per Page + Contact + Date

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    'Fact Table Grain Check' AS analysis,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(
        f.marketingPageId, '|',
        f.viewingcontactid, '|',
        f.visitdatekey
    )) AS distinct_page_contact_date,
    COUNT(*) - COUNT(DISTINCT CONCAT(
        f.marketingPageId, '|',
        f.viewingcontactid, '|',
        f.visitdatekey
    )) AS duplicate_rows,
    ROUND(COUNT(DISTINCT CONCAT(
        f.marketingPageId, '|',
        f.viewingcontactid, '|',
        f.visitdatekey
    )) / COUNT(*) * 100, 2) AS uniqueness_percent
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395);


-- =====================================================================================
-- ANALYSIS 2: Pages per Site Distribution
-- =====================================================================================
-- Understanding if sites have few pages or if interactions are concentrated

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    'Pages per Site' AS analysis,
    COUNT(DISTINCT w.websitename) AS total_sites,
    COUNT(DISTINCT f.marketingPageId) AS total_pages,
    ROUND(COUNT(DISTINCT f.marketingPageId) / COUNT(DISTINCT w.websitename), 2) AS avg_pages_per_site,
    MIN(page_count) AS min_pages_per_site,
    MAX(page_count) AS max_pages_per_site,
    PERCENTILE(page_count, 0.5) AS median_pages_per_site
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
LEFT JOIN
    page_to_website AS w
    ON f.marketingPageId = w.marketingPageId
LEFT JOIN (
    -- Subquery to get page count per site
    SELECT
        w2.websitename,
        COUNT(DISTINCT f2.marketingPageId) AS page_count
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f2
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d2
        ON d2.date_key = f2.visitdatekey
    LEFT JOIN
        page_to_website AS w2
        ON f2.marketingPageId = w2.marketingPageId
    WHERE
        d2.date >= DATE_ADD(CURRENT_DATE(), -395)
    GROUP BY
        w2.websitename
) site_pages ON w.websitename = site_pages.websitename
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395)
GROUP BY 'Pages per Site';


-- =====================================================================================
-- ANALYSIS 3: Site-Level Aggregation - What grain remains?
-- =====================================================================================
-- When we aggregate to site level, what dimensions remain?

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    'Site-Level Grain' AS analysis,
    COUNT(*) AS fact_table_rows,
    COUNT(DISTINCT CONCAT(
        w.websitename, '|',
        f.viewingcontactid, '|',
        f.visitdatekey
    )) AS site_contact_date_combinations,
    COUNT(DISTINCT w.websitename) AS distinct_sites,
    COUNT(DISTINCT f.viewingcontactid) AS distinct_contacts,
    COUNT(DISTINCT f.visitdatekey) AS distinct_dates,
    ROUND(COUNT(*) / COUNT(DISTINCT w.websitename), 0) AS avg_rows_per_site,
    ROUND(COUNT(*) / COUNT(DISTINCT f.viewingcontactid), 2) AS avg_rows_per_contact,
    ROUND(COUNT(*) / COUNT(DISTINCT f.visitdatekey), 0) AS avg_rows_per_date
FROM
    sharepoint_gold.pbi_db_interactions_metrics AS f
LEFT JOIN
    sharepoint_gold.pbi_db_dim_date AS d
    ON d.date_key = f.visitdatekey
LEFT JOIN
    page_to_website AS w
    ON f.marketingPageId = w.marketingPageId
WHERE
    d.date >= DATE_ADD(CURRENT_DATE(), -395);


-- =====================================================================================
-- ANALYSIS 4: Simulated Site-Level Aggregation Count
-- =====================================================================================
-- Exactly what Query 3 calculates - site + contact + date combinations

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
),
site_aggregated AS (
    SELECT
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        f.visitdatekey,
        f.viewingcontactid
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
        d.date >= DATE_ADD(CURRENT_DATE(), -395)
    GROUP BY
        w.websitename,
        e.employeebusinessdivision,
        e.employeeregion,
        f.visitdatekey,
        f.viewingcontactid
)
SELECT
    'Aggregated Row Count' AS analysis,
    COUNT(*) AS aggregated_rows,
    COUNT(DISTINCT websitename) AS distinct_sites,
    COUNT(DISTINCT viewingcontactid) AS distinct_contacts,
    COUNT(DISTINCT visitdatekey) AS distinct_dates,
    ROUND(COUNT(*) / COUNT(DISTINCT websitename), 0) AS rows_per_site,
    ROUND(COUNT(*) / COUNT(DISTINCT viewingcontactid), 2) AS rows_per_contact
FROM site_aggregated;


-- =====================================================================================
-- ANALYSIS 5: Distribution of interactions per site
-- =====================================================================================
-- Show how concentrated interactions are across sites

WITH page_to_website AS (
    SELECT DISTINCT marketingPageId, websitename
    FROM sharepoint_gold.pbi_db_website_page_investory
)
SELECT
    'Concentration Analysis' AS analysis,
    SUM(CASE WHEN rn <= 1 THEN interactions END) AS top_1_site_interactions,
    SUM(CASE WHEN rn <= 5 THEN interactions END) AS top_5_sites_interactions,
    SUM(CASE WHEN rn <= 10 THEN interactions END) AS top_10_sites_interactions,
    SUM(CASE WHEN rn <= 50 THEN interactions END) AS top_50_sites_interactions,
    SUM(interactions) AS total_interactions,
    ROUND(SUM(CASE WHEN rn <= 1 THEN interactions END) / SUM(interactions) * 100, 2) AS top_1_percent,
    ROUND(SUM(CASE WHEN rn <= 5 THEN interactions END) / SUM(interactions) * 100, 2) AS top_5_percent,
    ROUND(SUM(CASE WHEN rn <= 10 THEN interactions END) / SUM(interactions) * 100, 2) AS top_10_percent
FROM (
    SELECT
        w.websitename,
        COUNT(*) AS interactions,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
    FROM
        sharepoint_gold.pbi_db_interactions_metrics AS f
    LEFT JOIN
        sharepoint_gold.pbi_db_dim_date AS d
        ON d.date_key = f.visitdatekey
    LEFT JOIN
        page_to_website AS w
        ON f.marketingPageId = w.marketingPageId
    WHERE
        d.date >= DATE_ADD(CURRENT_DATE(), -395)
    GROUP BY
        w.websitename
) site_stats;


-- =====================================================================================
-- EXECUTION NOTES
-- =====================================================================================
-- Run each analysis separately to understand:
-- 1. Is the fact table already at Page+Contact+Date grain?
-- 2. How many pages per site on average?
-- 3. What is the site-level grain (Site+Contact+Date+Division+Region)?
-- 4. What is the simulated aggregated row count?
-- 5. How concentrated are interactions (80/20 rule)?
-- =====================================================================================
