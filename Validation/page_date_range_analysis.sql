-- =====================================================================================
-- Page Date Range Analysis - Count Distinct Viewing Contacts
-- =====================================================================================
-- Purpose: Calculate unique viewing contacts for specific pages within a 7-day
--          window from each page's minimum date (mindate + 6 days)
-- =====================================================================================

WITH page_dates AS (
    SELECT
        marketingpageid,
        MIN(date_format(to_date(visitdatekey, 'yyyyMMdd'), 'yyyy-MM-dd')) AS mindate,
        DATE_ADD(MIN(date_format(to_date(visitdatekey, 'yyyyMMdd'), 'yyyy-MM-dd')), 6) AS maxdate
    FROM
        sharepoint_gold.pbi_db_interactions_metrics
    WHERE
        marketingpageid IN (
            SELECT DISTINCT pageuuid
            FROM sharepoint_bronze.pages
            WHERE pageURL LIKE "%int-news-and-events%"
        )
    GROUP BY
        marketingpageid
),
final AS (
    SELECT
        i.marketingpageid,
        i.visitdatekey,
        i.viewingcontactid
    FROM
        sharepoint_gold.pbi_db_interactions_metrics i
    JOIN
        page_dates p
        ON i.marketingpageid = p.marketingpageid
        AND date_format(to_date(i.visitdatekey, 'yyyyMMdd'), 'yyyy-MM-dd') BETWEEN p.mindate AND p.maxdate
    WHERE
        i.marketingpageid IN (
            SELECT DISTINCT pageuuid
            FROM sharepoint_bronze.pages
            WHERE pageURL LIKE "%int-news-and-events%"
        )
)
SELECT COUNT(DISTINCT viewingcontactid) FROM final;
